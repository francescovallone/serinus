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
import '../http/http.dart';
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
  @pragma('vm:prefer-inline')
  Future<void> describe<T extends RouteHandlerSpec>(
    RouteContext<T> context, {
    required IncomingMessage request,
    required OutgoingMessage response,
    required Map<String, dynamic> params,
    ErrorHandler? errorHandler,
    bool rawBody = false,
    ObserveConfig? observeConfig,
  }) async {
    ExecutionContext? executionContext;
    try {
      final wrappedRequest = Request(request, params);
      executionContext = ExecutionContext(
        HostType.http,
        context.providers,
        context.values,
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
        providers: context.providers,
        values: context.values,
        hooksServices: context.hooksServices,
        modelProvider: modelProvider,
        rawBody: rawBody,
      );
      executionContext.attachHttpContext(requestContext);
      final observeHandle = context.observePlan.activate(requestContext);
      executionContext.observe = observeHandle;
      requestContext.observe = observeHandle;
      observeHandle?.step<void>(
        'route.${context.id}',
        (_) {},
        phase: ObservePhase.routing,
      );

      for (int i = 0; i < context.reqHooks.length; i++) {
        final hook = context.reqHooks[i];
        await _observeAsync<void>(
          executionContext,
          name: 'requestHook.${hook.runtimeType}',
          phase: ObservePhase.requestHook,
          body: () => hook.onRequest(executionContext!),
        );
        if (executionContext.response.body != null) {
          await _responseController.sendResponse(
            response,
            request,
            processResult(
              WrappedResponse(executionContext.response.body),
              executionContext,
            ),
            executionContext.response,
            viewEngine: viewEngine,
          );
          return;
        }
        if (executionContext.response.closed) {
          await _responseController.sendResponse(
            response,
            request,
            WrappedResponse(null),
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
        for (int i = 0; i < context.pipes.length; i++) {
          final pipe = context.pipes[i];
          await _observeAsync(
            executionContext,
            name: 'pipe.${pipe.runtimeType}',
            phase: ObservePhase.pipe,
            body: () => pipe.transform(executionContext!),
          );
        }
      }
      final middlewares =
          context.compiledMiddlewares; // Instant O(1) cache read
      final activeMiddlewares = <Middleware>[];
      if (middlewares.isNotEmpty) {
        final requestPath = request.uri.path;

        // Fast, allocation-free loop checking compiled regexes
        for (var i = 0; i < middlewares.length; i++) {
          if (middlewares[i].appliesTo(requestPath)) {
            activeMiddlewares.add(middlewares[i].middleware);
          }
        }
        final executor = MiddlewareExecutor();
        await executor.execute(
          activeMiddlewares,
          executionContext,
          response,
          onDataReceived: (data) async {
            await _executeOnResponse(context, executionContext!, data);
            data = processResult(data, executionContext);
            if (request.events.hasListener) {
              request.emit(
                RequestEvent.data,
                EventData(data: data, properties: executionContext.response),
              );
            }
            await _responseController.sendResponse(
              response,
              request,
              data,
              executionContext.response,
              viewEngine: viewEngine,
            );
            if (request.events.hasListener) {
              request.emit(
                RequestEvent.close,
                EventData(
                  data: data,
                  properties: executionContext.response
                    ..addHeadersFrom(response.currentHeaders),
                ),
              );
            }
          },
        );
        if (response.isClosed) {
          return;
        }
      }
      await _executeBeforeHandle(executionContext, context);
      final handler = spec.handler;
      final handlerResult = await _observeAsync(
        executionContext,
        name: 'handler.${context.id}',
        phase: ObservePhase.handle,
        body: () => handler.call(requestContext),
      );
      final responseData = WrappedResponse(handlerResult);
      await _executeAfterHandle(executionContext, context, responseData);
      await _executeOnResponse(context, executionContext, responseData);
      final data = responseData.data;
      if (data is View) {
        if (request.events.hasListener) {
          request.emit(
            RequestEvent.data,
            EventData(data: data, properties: executionContext.response),
          );
          request.emit(
            RequestEvent.close,
            EventData(
              data: data,
              properties: executionContext.response
                ..addHeadersFrom(response.currentHeaders),
            ),
          );
        }
        await _responseController.render(
          response,
          data,
          executionContext.response,
        );
      } else if (data is Redirect) {
        if (request.events.hasListener) {
          request.emit(
            RequestEvent.data,
            EventData(data: data, properties: executionContext.response),
          );
          request.emit(
            RequestEvent.close,
            EventData(
              data: data,
              properties: executionContext.response
                ..addHeadersFrom(response.currentHeaders),
            ),
          );
        }
        await _responseController.redirect(
          response,
          data,
          executionContext.response,
        );
      } else {
        if (request.events.hasListener) {
          request.emit(
            RequestEvent.data,
            EventData(
              data: responseData.data,
              properties: executionContext.response,
            ),
          );
        }
        await _responseController.sendResponse(
          response,
          request,
          processResult(responseData, executionContext),
          executionContext.response,
          viewEngine: viewEngine,
        );
        if (request.events.hasListener) {
          request.emit(
            RequestEvent.close,
            EventData(
              data: responseData.data,
              properties: executionContext.response,
            ),
          );
        }
      }
    } on SerinusException catch (e, stackTrace) {
      executionContext ??= ExecutionContext(
        HostType.http,
        {
          for (var provider in context.moduleScope.unifiedProviders)
            provider.runtimeType: provider,
        },
        context.values,
        context.hooksServices,
        HttpArgumentsHost(Request(request, params)),
      );
      executionContext.response.statusCode = e.statusCode;
      executionContext.response.contentType ??= jsonContentType;
      final result = await _executeOnException(executionContext, context, e);
      if (result != null) {
        await _executeOnResponse(context, executionContext, result);
        await _responseController.sendResponse(
          response,
          request,
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
            request,
            processResult(WrappedResponse(errorResponse), executionContext),
            executionContext.response,
            viewEngine: viewEngine,
          );
        }
      } else {
        await _responseController.sendResponse(
          response,
          request,
          WrappedResponse(jsonEncode(e.toJson())),
          executionContext.response,
          viewEngine: viewEngine,
        );
      }
    } finally {
      if (executionContext != null && observeConfig != null) {
        await observeConfig.flush(executionContext);
      }
    }
  }

  Future<WrappedResponse?> _executeOnException(
    ExecutionContext executionContext,
    RouteContext context,
    SerinusException exception,
  ) async {
    for (int i = 0; i < context.exceptionFilters.length; i++) {
      final filter = context.exceptionFilters.elementAt(i);
      if (filter.catchTargets.contains(exception.runtimeType) ||
          filter.catchTargets.isEmpty) {
        await _observeAsync<void>(
          executionContext,
          name: 'exception.${filter.runtimeType}',
          phase: ObservePhase.exception,
          body: () => filter.onException(executionContext, exception),
        );
        if (executionContext.response.body != null) {
          return WrappedResponse(executionContext.response.body);
        }
        if (executionContext.response.closed) {
          return WrappedResponse(null);
        }
      }
    }
    return null;
  }

  Future<void> _executeAfterHandle(
    ExecutionContext executionContext,
    RouteContext context,
    WrappedResponse response,
  ) async {
    if (context.afterHooks.isEmpty) {
      return;
    }
    for (int i = 0; i < context.afterHooks.length; i++) {
      final hook = context.afterHooks[i];
      await _observeAsync<void>(
        executionContext,
        name: 'afterHandle.${hook.runtimeType}',
        phase: ObservePhase.afterHandle,
        body: () => hook.afterHandle(executionContext, response),
      );
    }
  }

  Future<void> _executeBeforeHandle(
    ExecutionContext executionContext,
    RouteContext context,
  ) async {
    if (context.beforeHooks.isEmpty) {
      return;
    }
    for (int i = 0; i < context.beforeHooks.length; i++) {
      final hook = context.beforeHooks[i];
      await _observeAsync<void>(
        executionContext,
        name: 'beforeHandle.${hook.runtimeType}',
        phase: ObservePhase.beforeHandle,
        body: () => hook.beforeHandle(executionContext),
      );
    }
  }

  /// The [processResult] method is used to process the result of a route handler.
  /// It converts the result to the appropriate format based on the content type
  WrappedResponse processResult(
    WrappedResponse result,
    ExecutionContext context,
  ) {
    final data = result.data;
    if (data == null) {
      return result;
    }

    Object? responseData;

    // Prefer to produce bytes for JSON-able and model objects here, so downstream
    // sending code doesn't re-encode and we avoid double-encoding.
    if (data is Uint8List || data is List<int> || data is File) {
      context.response.contentType ??= ContentType.binary;
    } else if (data is Map || data is Iterable) {
      responseData = sharedJsonUtf8Encoder.convert(data);
      result.isEncoded = true;
      context.response.contentType ??= jsonContentType;
    } else if (data is String) {
      responseData = data;
      context.response.contentType ??= ContentType.text;
    } else if (data is num || data is bool) {
      responseData = data.toString();
      context.response.contentType ??= ContentType.text;
    } else {
      final modelKey = data.runtimeType.toString();
      final models = modelProvider?.toJsonModels;
      if (models != null && models.containsKey(modelKey)) {
        final modelObj = modelProvider?.to(data);
        responseData = sharedJsonUtf8Encoder.convert(modelObj);
        result.isEncoded = true;
        context.response.contentType ??= jsonContentType;
      }
    }

    result.data = responseData ?? data;
    return result;
  }

  Future<void> _executeOnResponse(
    RouteContext context,
    ExecutionContext executionContext,
    WrappedResponse responseData,
  ) async {
    if (context.resHooks.isEmpty) {
      return;
    }
    for (int i = 0; i < context.resHooks.length; i++) {
      final hook = context.resHooks[i];
      await _observeAsync<void>(
        executionContext,
        name: 'response.${hook.runtimeType}',
        phase: ObservePhase.response,
        body: () => hook.onResponse(executionContext, responseData),
      );
    }
  }

  Future<T> _observeAsync<T>(
    ExecutionContext executionContext, {
    required String name,
    required ObservePhase phase,
    required Future<T> Function() body,
  }) async {
    final observe = executionContext.observe;
    if (observe == null) {
      return body();
    }
    return observe.stepAsync(name, (_) => body(), phase: phase);
  }
}
