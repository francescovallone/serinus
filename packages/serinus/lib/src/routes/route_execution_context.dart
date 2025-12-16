import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import '../adapters/adapters.dart';
import '../containers/models_provider.dart';
import '../contexts/contexts.dart';
import '../contexts/route_context.dart';
import '../core/core.dart';
import '../core/middlewares/middleware_executor.dart';
import '../engines/view_engine.dart';
import '../enums/enums.dart';
import '../exceptions/exceptions.dart';
import '../extensions/iterable_extansions.dart';
import '../extensions/object_extensions.dart';
import '../http/http.dart';
import '../utils/wrapped_response.dart';
import 'route_response_controller.dart';

/// The [RouteExecutionContext] class is used to handle the execution context of a route.
/// It provides methods to handle requests, responses, and errors.
class RouteExecutionContext {
  /// The [RouteResponseController] is used to handle responses for routes.
  /// It provides methods to send responses, redirect, and render views.
  final RouteResponseController _responseController;

  static JsonUtf8Encoder _jsonUtf8Encoder = JsonUtf8Encoder();

  /// The [modelProvider] is used to convert models to and from JSON.
  /// It is optional and can be null if models are not used in the application.
  final ModelProvider? modelProvider;

  /// The [viewEngine] is used to render views.
  /// It is optional and can be null if views are not used in the application.
  final ViewEngine? viewEngine;

  /// The [RouteExecutionContext] constructor is used to create a new instance of the [RouteExecutionContext] class.
  /// It takes a [RouteResponseController] and optional parameters for [modelProvider] and [viewEngine].
  const RouteExecutionContext(
    this._responseController, {
    this.modelProvider,
    this.viewEngine,
  });

  /// The [describe] method is used to describe the route execution context.
  /// It returns a [HandlerFunction] that can be used to handle the request and response.
  /// It takes a [RouteContext] and optional parameters such as [errorHandler], [notFoundHandler], and [rawBody].
  /// The [errorHandler] is used to handle errors that occur during the request processing.
  /// The [rawBody] parameter indicates whether the body should be treated as raw binary data
  @pragma('vm:prefer-inline')
  Future<void> describe<T extends RouteHandlerSpec>(
    RouteContext<T> context, {
    required IncomingMessage request,
    required OutgoingMessage response,
    required Map<String, dynamic> params,
    ErrorHandler? errorHandler,
    bool rawBody = false,
  }) async {
      ExecutionContext? executionContext;
      try {
        final wrappedRequest = Request(request, params);
        final providers = {
          for (var provider in context.moduleScope.unifiedProviders)
            provider.runtimeType: provider,
        };
        executionContext = ExecutionContext(
          HostType.http,
          providers,
          context.hooksServices,
          HttpArgumentsHost(wrappedRequest),
        );
        if (context.spec is! RestRouteHandlerSpec) {
          throw StateError(
            'Unsupported route handler specification: ${context.spec.runtimeType}',
          );
        }
        final spec = context.spec as RestRouteHandlerSpec;
        final requestContext = await spec.buildRequestContext(
          request: wrappedRequest,
          providers: providers,
          hooksServices: context.hooksServices,
          modelProvider: modelProvider,
          rawBody: rawBody,
        );
        executionContext.attachHttpContext(requestContext);
        for (final hook in context.reqHooks) {
          await hook.onRequest(executionContext);
          if (executionContext.response.closed) {
            await _responseController.sendResponse(
              response,
              processResult(
                WrappedResponse(executionContext.response.body),
                executionContext,
              ),
              executionContext.response,
              viewEngine: viewEngine,
            );
            return;
          }
        }
        if (context.metadata.isNotEmpty) {
          executionContext.metadata.addAll(
            await context.initMetadata(executionContext),
          );
        }
        if (context.pipes.isNotEmpty) {
          for (final pipe in context.pipes) {
            await pipe.transform(executionContext);
          }
        }
        final middlewares = context.getMiddlewares(request);
        if (middlewares.isNotEmpty) {
          final executor = MiddlewareExecutor();
          await executor.execute(
            middlewares,
            executionContext,
            response,
            onDataReceived: (data) async {
              await _executeOnResponse(context, executionContext!, data);
              data = processResult(data, executionContext);
              request.emit(
                RequestEvent.data,
                EventData(data: data, properties: executionContext.response),
              );
              await _responseController.sendResponse(
                response,
                data,
                executionContext.response,
                viewEngine: viewEngine,
              );
              request.emit(
                RequestEvent.close,
                EventData(
                  data: data,
                  properties: executionContext.response
                    ..headers.addAll(
                      (response.currentHeaders is SerinusHeaders)
                          ? response.currentHeaders.values
                          : (response.currentHeaders as HttpHeaders).toMap(),
                    ),
                ),
              );
            },
          );
          if (response.isClosed) {
            return;
          }
        }
        await _executeBeforeHandle(executionContext, context);
        final handler = spec.handler;
        final handlerResult = await handler.call(requestContext);
        final responseData = WrappedResponse(handlerResult);
        await _executeAfterHandle(executionContext, context, responseData);
        await _executeOnResponse(context, executionContext, responseData);
        final currentResponseHeaders =
            (response.currentHeaders is SerinusHeaders)
            ? response.currentHeaders.values
            : (response.currentHeaders as HttpHeaders).toMap();
        final data = responseData.data;
        if (data is View) {
          request.emit(
            RequestEvent.data,
            EventData(data: data, properties: executionContext.response),
          );
          request.emit(
            RequestEvent.close,
            EventData(
              data: data,
              properties: executionContext.response
                ..addHeaders(currentResponseHeaders),
            ),
          );
          await _responseController.render(
            response,
            data,
            executionContext.response,
          );
        } else if (data is Redirect) {
          request.emit(
            RequestEvent.redirect,
            EventData(data: responseData.data, properties: executionContext.response),
          );
          await _responseController.redirect(
            response,
            data,
            executionContext.response,
          );
        } else {
          request.emit(
            RequestEvent.data,
            EventData(data: data, properties: executionContext.response),
          );
          request.emit(
            RequestEvent.close,
            EventData(
              data: data,
              properties: executionContext.response
                ..addHeaders(currentResponseHeaders),
            ),
          );
          await _responseController.sendResponse(
            response,
            processResult(responseData, executionContext),
            executionContext.response,
            viewEngine: viewEngine,
          );
        }
      } on SerinusException catch (e, stackTrace) {
        executionContext ??= ExecutionContext(
          HostType.http,
          {
            for (var provider in context.moduleScope.unifiedProviders)
              provider.runtimeType: provider,
          },
          context.hooksServices,
          HttpArgumentsHost(Request(request, params)),
        );
        executionContext.response.statusCode = e.statusCode;
        executionContext.response.contentType ??= ContentType.json;
        final result = await _executeOnException(executionContext, context, e);
        if (result != null) {
          await _responseController.sendResponse(
            response,
            processResult(result, executionContext),
            executionContext.response,
            viewEngine: viewEngine,
          );
          return;
        }
        await _executeOnResponse(context, executionContext, WrappedResponse(e));
        if (errorHandler != null) {
          final errorResponse = errorHandler(e, stackTrace);
          if (errorResponse != null) {
            await _responseController.sendResponse(
              response,
              processResult(WrappedResponse(errorResponse), executionContext),
              executionContext.response,
              viewEngine: viewEngine,
            );
          }
        } else {
          await _responseController.sendResponse(
            response,
            WrappedResponse(jsonEncode(e.toJson())),
            executionContext.response,
            viewEngine: viewEngine,
          );
        }
      }
  }

  Future<WrappedResponse?> _executeOnException(
    ExecutionContext executionContext,
    RouteContext context,
    SerinusException exception,
  ) async {
    for (final filter in context.exceptionFilters) {
      if (filter.catchTargets.contains(exception.runtimeType) ||
          filter.catchTargets.isEmpty) {
        await filter.onException(executionContext, exception);
        if (executionContext.response.closed) {
          break;
        }
      }
    }
    if (executionContext.response.body != null) {
      return WrappedResponse(executionContext.response.body);
    }
    return null;
  }

  Future<void> _executeAfterHandle(
    ExecutionContext executionContext,
    RouteContext context,
    WrappedResponse response,
  ) async {
    for (final hook in context.afterHooks) {
      await hook.afterHandle(executionContext, response);
    }
  }

  Future<void> _executeBeforeHandle(
    ExecutionContext executionContext,
    RouteContext context,
  ) async {
    for (final hook in context.beforeHooks) {
      await hook.beforeHandle(executionContext);
    }
  }

  /// The [processResult] method is used to process the result of a route handler.
  /// It converts the result to the appropriate format based on the content type
  WrappedResponse processResult(
    WrappedResponse result,
    ExecutionContext context,
  ) {
    Object? responseData;
    if (result.data == null) {
      return result;
    }
    // Prefer to produce bytes for JSON-able and model objects here, so downstream
    // sending code doesn't re-encode and we avoid double-encoding.
    if (result.data?.canBeJson() ?? false) {
      responseData = _jsonUtf8Encoder.convert(result.data);
      context.response.contentType ??= ContentType.json;
    }

    if (modelProvider?.toJsonModels.containsKey(
          result.data.runtimeType.toString(),
        ) ??
        false) {
      final modelObj = modelProvider?.to(result.data);
      responseData = _jsonUtf8Encoder.convert(modelObj);
      context.response.contentType ??= ContentType.json;
    }

    if (result.data is Uint8List || result.data is File) {
      context.response.contentType ??= ContentType.binary;
    }

    result.data = responseData ?? result.data;
    return result;
  }

  Future<void> _executeOnResponse(
    RouteContext context,
    ExecutionContext executionContext,
    WrappedResponse responseData,
  ) async {
    for (final hook in context.resHooks) {
      await hook.onResponse(executionContext, responseData);
    }
  }
}
