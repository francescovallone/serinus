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
        await wrappedRequest.parseBody(rawBody);
        executionContext = ExecutionContext(
          HostType.http,
          {
            for (var provider in context.moduleScope.unifiedProviders)
              provider.runtimeType: provider,
          },
          context.hooksServices,
          HttpArgumentsHost(wrappedRequest),
        );
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
        final requestContext = executionContext.switchToHttp();
        if (context.schema != null) {
          final schema = context.schema!;
          final Map<String, dynamic> toParse = {};
          if (schema.body != null) {
            toParse['body'] = requestContext.body.value;
          }
          if (schema.query != null) {
            toParse['query'] = requestContext.query;
          }
          if (schema.params != null) {
            toParse['params'] = requestContext.params;
          }
          if (schema.headers != null) {
            toParse['headers'] = {
              for (final key in schema.headers!.fields.keys)
                key: requestContext.headers[key],
            };
          }
          if (schema.session != null) {
            toParse['session'] = requestContext.request.session.all;
          }
          final result = await schema.tryParse(
            bodyValue: toParse['body'],
            queryValue: toParse['query'],
            paramsValue: toParse['params'],
            headersValue: Map<String, dynamic>.from(toParse['headers'] ?? {}),
            sessionValue: Map<String, dynamic>.from(toParse['session'] ?? {}),
          );
          requestContext.headers.addAll(
            result['headers'] ?? <String, String>{},
          );
          requestContext.params.addAll(result['params'] ?? {});
          requestContext.query.addAll(result['query'] ?? {});
          requestContext.body =
              result.containsKey('body') && result['body'] != null
                  ? JsonBody.fromJson(result['body'] ?? {})
                  : requestContext.body;
        }
        if (context.pipes.isNotEmpty) {
          for (final pipe in context.pipes) {
            await pipe.transform(executionContext);
          }
        }
        if (!rawBody) {
          requestContext.body =
              resolveBody(context.spec.body, requestContext) ??
              requestContext.body;
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
                  properties:
                      executionContext.response
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
              if (context.spec.body != null) requestContext.body.value,
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
              properties:
                  executionContext.response
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
              properties:
                  executionContext.response
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
            WrappedResponse(e.message),
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

  /// The [resolveBody] method is used to resolve the body of the request based on the expected type.
  /// It checks the type of the body and returns the appropriate value.
  dynamic resolveBody(dynamic body, RequestContext context) {
    if (body == null) {
      return null;
    }
    if (body == String) {
      if (context.body is! TextBody) {
        throw PreconditionFailedException('The body is not a string');
      }
      return context.body.value;
    }
    if ((('$body'.startsWith('Map') || '$body'.contains('List<')) &&
            '$body'.endsWith('>')) ||
        '$body' == 'Map') {
      if (context.body is! JsonBody && context.body is! FormDataBody) {
        throw PreconditionFailedException('The body is not a json object');
      }
      final requestBody = context.body;
      if (requestBody is FormDataBody) {
        return requestBody.asMap();
      }
      return requestBody.value;
    }
    if (body == Uint8List) {
      if (context.body is! RawBody) {
        throw PreconditionFailedException('The body is not a binary');
      }
      return context.body.value;
    }
    if (body == FormData) {
      if (context.body is! FormDataBody) {
        throw PreconditionFailedException('The body is not a form data');
      }
      return context.body.value;
    }
    if (modelProvider != null) {
      try {
        final requestBody = context.body;
        if (requestBody is FormDataBody) {
          return modelProvider!.from(body, {
            ...requestBody.asMap(),
            ...Map<String, dynamic>.fromEntries(
              requestBody.value.files.entries,
            ),
          });
        }
        if (requestBody is JsonBody) {
          if (requestBody is JsonList) {
            return requestBody.value
                .map((e) => modelProvider!.from(body, e))
                .toList();
          } else {
            return modelProvider!.from(body, requestBody.value);
          }
        }
      } catch (e) {
        throw PreconditionFailedException(
          'The body cannot be converted to a valid model',
        );
      }
    }
    throw PreconditionFailedException('The body type is not supported: $body');
  }
}
