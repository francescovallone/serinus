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
import '../services/json_utils.dart';
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
  HandlerFunction describe<T extends RouteHandlerSpec>(
    RouteContext<T> context, {
    ErrorHandler? errorHandler,
    bool rawBody = false,
    ObserveConfig? observe,
  }) {
    return (
      IncomingMessage request,
      OutgoingMessage response,
      Map<String, dynamic> params,
    ) async {
      ExecutionContext? executionContext;
      var sinksFlushed = false;
      Future<void> flushSinks() async {
        if (sinksFlushed) {
          return;
        }
        sinksFlushed = true;
        if (executionContext != null) {
          await observe?.flush(executionContext);
        }
      }
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
        ObserveHandle? observeHandle;
        if (context.observePlan.enabled) {
          observeHandle = context.observePlan.activate(requestContext);
          executionContext.observe = observeHandle;
          requestContext.observe = observeHandle;
        }
        for (final hook in context.reqHooks) {
          if (observeHandle != null) {
            await observeHandle.stepAsync(
              'hook.request',
              () => hook.onRequest(executionContext!),
              phase: ObservePhase.requestHook,
            );
          } else {
            await hook.onRequest(executionContext);
          }
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
            await flushSinks();
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
            if (observeHandle != null) {
              await observeHandle.stepAsync(
                'pipe',
                () => pipe.transform(executionContext!),
                phase: ObservePhase.pipe,
              );
            } else {
              await pipe.transform(executionContext);
            }
          }
        }
        final middlewares = context.getMiddlewares(request);
        if (middlewares.isNotEmpty) {
          final executor = MiddlewareExecutor();
          Future<void> runMiddlewares() {
            return executor.execute(
              middlewares,
              executionContext!,
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
                await flushSinks();
              },
            );
          }

          if (observeHandle != null) {
            await observeHandle.stepAsync(
              'middleware',
              runMiddlewares,
              phase: ObservePhase.middleware,
            );
          } else {
            await runMiddlewares();
          }
          if (response.isClosed) {
            await flushSinks();
            return;
          }
        }
        if (observeHandle != null) {
          await observeHandle.stepAsync(
            'beforeHandle',
            () => _executeBeforeHandle(executionContext!, context),
            phase: ObservePhase.beforeHandle,
          );
        } else {
          await _executeBeforeHandle(executionContext, context);
        }
        final handler = spec.handler;
        final handlerResult = observeHandle != null
            ? await observeHandle.stepAsync(
                'handle',
                () => handler.call(requestContext),
                phase: ObservePhase.handle,
              )
            : await handler.call(requestContext);
        final responseData = WrappedResponse(handlerResult);
        if (observeHandle != null) {
          await observeHandle.stepAsync(
            'afterHandle',
            () => _executeAfterHandle(executionContext!, context, responseData),
            phase: ObservePhase.afterHandle,
          );
          await observeHandle.stepAsync(
            'response',
            () => _executeOnResponse(context, executionContext!, responseData),
            phase: ObservePhase.response,
          );
        } else {
          await _executeAfterHandle(executionContext, context, responseData);
          await _executeOnResponse(context, executionContext, responseData);
        }
        WrappedResponse result = processResult(responseData, executionContext);
        final currentResponseHeaders =
            (response.currentHeaders is SerinusHeaders)
            ? response.currentHeaders.values
            : (response.currentHeaders as HttpHeaders).toMap();
        final data = result.data;
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
          await flushSinks();
        } else if (data is Redirect) {
          request.emit(
            RequestEvent.redirect,
            EventData(data: result.data, properties: executionContext.response),
          );
          await _responseController.redirect(
            response,
            data,
            executionContext.response,
          );
          await flushSinks();
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
            result,
            executionContext.response,
            viewEngine: viewEngine,
          );
          await flushSinks();
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
        final observeHandle = executionContext.observe;
        executionContext.response.statusCode = e.statusCode;
        executionContext.response.contentType ??= ContentType.json;
        final result = observeHandle != null
            ? await observeHandle.stepAsync(
                'exception',
                () => _executeOnException(executionContext!, context, e),
                phase: ObservePhase.exception,
              )
            : await _executeOnException(executionContext, context, e);
        if (result != null) {
          await _responseController.sendResponse(
            response,
            processResult(result, executionContext),
            executionContext.response,
            viewEngine: viewEngine,
          );
          await flushSinks();
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
            await flushSinks();
          }
        } else {
          await _responseController.sendResponse(
            response,
            WrappedResponse(jsonEncode(e.toJson())),
            executionContext.response,
            viewEngine: viewEngine,
          );
          await flushSinks();
        }
      }
    };
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
      final prepared = parseJsonToResponse(result.data, modelProvider);
      responseData = Uint8List.fromList(_jsonUtf8Encoder.convert(prepared));
      context.response.contentType ??= ContentType.json;
    }

    if (modelProvider?.toJsonModels.containsKey(
          result.data.runtimeType.toString(),
        ) ??
        false) {
      final modelObj = modelProvider?.to(result.data);
      responseData = Uint8List.fromList(_jsonUtf8Encoder.convert(modelObj));
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
