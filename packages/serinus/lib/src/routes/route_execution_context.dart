import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import '../adapters/adapters.dart';
import '../containers/model_provider.dart';
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
import '../services/json_utils.dart';
import '../utils/wrapped_response.dart';
import 'route_response_controller.dart';

/// The [RouteExecutionContext] class is used to handle the execution context of a route.
/// It provides methods to handle requests, responses, and errors.
class RouteExecutionContext {
  /// The [RouteResponseController] is used to handle responses for routes.
  /// It provides methods to send responses, redirect, and render views.
  final RouteResponseController _responseController;

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
  HandlerFunction describe(
    RouteContext context, {
    ErrorHandler? errorHandler,
    bool rawBody = false,
  }) {
    return (
      IncomingMessage request,
      OutgoingMessage response,
      Map<String, dynamic> params,
    ) async {
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
        final requestContext = await RequestContext.create<dynamic>(
          request: wrappedRequest,
          providers: providers,
          hooksServices: context.hooksServices,
          modelProvider: modelProvider,
          rawBody: rawBody,
          explicitType: context.spec.body,
          shouldValidateMultipart: context.spec.shouldValidateMultipart,
        );
        executionContext.attachHttpContext(requestContext);
        for (final hook in context.hooksContainer.reqHooks) {
          await hook.onRequest(executionContext);
          if (executionContext.response.closed) {
            await _responseController.sendResponse(
              response,
              WrappedResponse(null),
              executionContext.response,
              viewEngine: viewEngine,
            );
            return;
          }
        }
        executionContext.metadata.addAll(
          await context.initMetadata(executionContext),
        );
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
              data = _processResult(data, executionContext);
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
                      (response.currentHeaders as HttpHeaders).toMap(),
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
        Object? handlerResult;
        final handler = context.spec.handler;
        if (context.isStatic) {
          handlerResult = handler;
          if (handler is SerinusException) {
            throw handler;
          }
        }
        if (handler is Function) {
          if (handler is ReqResHandler) {
            handlerResult = await handler.call(requestContext);
          } else if (handler is SyncReqResHandler) {
            handlerResult = handler.call(requestContext);
          } else {
            handlerResult = Function.apply(handler, [
              requestContext,
              if (context.spec.body != null) requestContext.body,
              ...requestContext.params.values,
            ]);
            if (handlerResult is Future) {
              handlerResult = await handlerResult;
            }
          }
        }
        final responseData = WrappedResponse(handlerResult);
        await _executeAfterHandle(executionContext, context, responseData);
        await _executeOnResponse(context, executionContext, responseData);
        WrappedResponse result = _processResult(responseData, executionContext);
        if (result.data is View) {
          request.emit(
            RequestEvent.data,
            EventData(data: result.data, properties: executionContext.response),
          );
          request.emit(
            RequestEvent.close,
            EventData(
              data: result.data,
              properties: executionContext.response
                ..headers.addAll(
                  (response.currentHeaders as HttpHeaders).toMap(),
                ),
            ),
          );
          await _responseController.render(
            response,
            result.data as View,
            executionContext.response,
          );
        } else if (result.data is Redirect) {
          request.emit(
            RequestEvent.redirect,
            EventData(data: result.data, properties: executionContext.response),
          );
          await _responseController.redirect(
            response,
            result.data as Redirect,
            executionContext.response,
          );
        } else {
          request.emit(
            RequestEvent.data,
            EventData(data: result.data, properties: executionContext.response),
          );
          request.emit(
            RequestEvent.close,
            EventData(
              data: result.data,
              properties: executionContext.response
                ..headers.addAll(
                  (response.currentHeaders as HttpHeaders).toMap(),
                ),
            ),
          );
          await _responseController.sendResponse(
            response,
            result,
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
        await _executeOnException(executionContext, context, e);
        await _executeOnResponse(context, executionContext, WrappedResponse(e));
        if (errorHandler != null) {
          final errorResponse = errorHandler(e, stackTrace);
          if (errorResponse != null) {
            await _responseController.sendResponse(
              response,
              _processResult(WrappedResponse(errorResponse), executionContext),
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
    };
  }

  Future<void> _executeOnException(
    ExecutionContext executionContext,
    RouteContext context,
    SerinusException exception,
  ) async {
    for (final filter in context.exceptionFilters) {
      if (filter.catchTargets.contains(exception.runtimeType) ||
          filter.catchTargets.isEmpty) {
        await filter.onException(executionContext, exception);
      }
    }
  }

  Future<void> _executeAfterHandle(
    ExecutionContext executionContext,
    RouteContext context,
    WrappedResponse response,
  ) async {
    for (final hook in context.hooksContainer.afterHooks) {
      await hook.afterHandle(executionContext, response);
    }
  }

  Future<void> _executeBeforeHandle(
    ExecutionContext executionContext,
    RouteContext context,
  ) async {
    for (final hook in context.hooksContainer.beforeHooks) {
      await hook.beforeHandle(executionContext);
    }
  }

  WrappedResponse _processResult(
    WrappedResponse result,
    ExecutionContext context,
  ) {
    Object? responseData;
    if (result.data == null) {
      return result;
    }
    if (result.data?.canBeJson() ?? false) {
      responseData = JsonUtf8Encoder().convert(
        parseJsonToResponse(result.data, modelProvider),
      );
      context.response.contentType ??= ContentType.json;
    }
    if (modelProvider?.toJsonModels.containsKey(result.data.runtimeType) ??
        false) {
      responseData = JsonUtf8Encoder().convert(modelProvider?.to(result.data));
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
    for (final hook in context.hooksContainer.resHooks) {
      await hook.onResponse(executionContext, responseData);
    }
  }
}
