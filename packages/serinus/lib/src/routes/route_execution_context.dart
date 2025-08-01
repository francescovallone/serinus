import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import '../adapters/adapters.dart';
import '../containers/model_provider.dart';
import '../contexts/contexts.dart';
import '../contexts/route_context.dart';
import '../core/core.dart';
import '../engines/view_engine.dart';
import '../enums/enums.dart';
import '../exceptions/exceptions.dart';
import '../extensions/object_extensions.dart';
import '../http/http.dart';
import '../mixins/mixins.dart';
import '../services/json_utils.dart';
import '../utils/wrapped_response.dart';
import 'route_response_controller.dart';

class RouteExecutionContext {
  
  final RouteResponseController _responseController;

  final ModelProvider? modelProvider;

  final ViewEngine? viewEngine;

  const RouteExecutionContext(this._responseController, {this.modelProvider, this.viewEngine});

  HandlerFunction describe(
    RouteContext context,
    {
      ErrorHandler? errorHandler,
      NotFoundHandler? notFoundHandler,
      bool rawBody = false
    }
  ) {
    return (IncomingMessage request, OutcomingMessage response, Map<String, dynamic> params) async {
      RequestContext? requestContext;
      try {
        final currentProperties = ResponseContext({}, {});
        final wrappedRequest = Request(request, params);
        await wrappedRequest.parseBody(rawBody);
        for (final hook in context.hooksContainer.reqHooks) {
          await hook.onRequest(wrappedRequest, currentProperties);
          if (currentProperties.closed) {
            await _responseController.sendResponse(response, null, currentProperties, viewEngine: viewEngine);
            return;
          }
        }
        final requestContext = RequestContext.fromRouteContext(wrappedRequest, context);
        requestContext.metadata = await context.initMetadata(requestContext);
        requestContext.body = _resolveBody(context.spec.body, requestContext) ?? requestContext.body;
        if(context.schema != null) {
          final schema = context.schema!;
          final Map<String, dynamic> toParse = {};
          if (schema.body != null) {
            toParse['body'] = requestContext.body.value;
          }
          if (schema.query != null) {
            toParse['query'] = requestContext.request.query;
          }
          if (schema.params != null) {
            toParse['params'] = requestContext.request.params;
          }
          if (schema.headers != null) {
            toParse['headers'] = {
              for (final key in schema.headers!.fields.keys)
                key: requestContext.request.headers[key]
            };
          }
          if (schema.session != null) {
            toParse['session'] = requestContext.request.session.all;
          }
          final result = await schema.tryParse(value: toParse);
          requestContext.request.headers.addAll(result['headers'] ?? <String, String>{});
          requestContext.request.params.addAll(result['params'] ?? {});
          requestContext.request.query.addAll(result['query'] ?? {});
          requestContext.body = result['body'] ?? requestContext.body;
        }
        final middlewares = context.getMiddlewares(wrappedRequest.params);
        if (middlewares.isNotEmpty) {
          await _handleMiddlewares(context, requestContext, middlewares, response, request);
          if (response.isClosed) {
            return;
          }
        }
        await _executeBeforeHandle(requestContext, context);
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
              context,
              requestContext.body.value,
              ...requestContext.params.values
            ]);
            if (handlerResult is Future) {
              handlerResult = await handlerResult;
            }
          }
        }
        final responseData = WrappedResponse(handlerResult);
        await _executeAfterHandle(requestContext, context, responseData);
        await _executeOnResponse(context, requestContext, responseData);
        Object? result = _processResult(responseData, requestContext);
        await _responseController.sendResponse(
          response,
          result,
          requestContext.res,
          viewEngine: viewEngine,
        );
      } on SerinusException catch (e, stackTrace) {
        final currentReqContext = requestContext ?? RequestContext(
          Request(request),
          {
            for (final provider in context.moduleScope.providers)
              provider.runtimeType: provider
          },
          context.hooksContainer.services
        );
        request.emit(
          RequestEvent.error, 
          EventData(
            data: e,
            properties: currentReqContext.res
          )
        );
        await _executeOnException(
          currentReqContext,
          context,
          e
        );
        if (errorHandler != null) {
          final errorResponse = errorHandler(e, stackTrace);
          if (errorResponse != null) {
            await _responseController.sendResponse(
              response,
              _processResult(WrappedResponse(errorResponse), currentReqContext),
              currentReqContext.res,
              viewEngine: viewEngine,
            );
          }
        } else {
          await _responseController.sendResponse(
            response,
            e.toBytes(),
            currentReqContext.res,
            viewEngine: viewEngine,
          );
        }
      }
    };
  }

  Future<void> _executeOnException(
    RequestContext requestContext,
    RouteContext context,
    SerinusException exception,
  ) async {
    for (final hook in context.hooksContainer.exceptionHooks) {
      if (hook.exceptionTypes.contains(exception.runtimeType)) {
        await hook.onException(requestContext, exception);
      }
    }
  }

  Future<void> _executeAfterHandle(
    RequestContext requestContext,
    RouteContext context,
    WrappedResponse response,
  ) async {
    for (final hook in context.hooksContainer.afterHooks) {
      await hook.afterHandle(requestContext, response);
    }
    if (context.spec.route is OnAfterHandle) {
      await (context.spec.route as OnAfterHandle)
          .afterHandle(requestContext, response);
    }
  }

  Future<void> _executeBeforeHandle(RequestContext requestContext, RouteContext context) async {
    for (final hook in context.hooksContainer.beforeHooks) {
      await hook.beforeHandle(requestContext);
    }
    if(context.spec.route is OnBeforeHandle) {
      await (context.spec.route as OnBeforeHandle).beforeHandle(requestContext);
    }
  }

  WrappedResponse _processResult(
      WrappedResponse result, RequestContext context) {
    Object? responseData;
    if(result.data == null) {
      return result;
    }
    if (result.data?.canBeJson() ?? false) {
      responseData =
          JsonUtf8Encoder().convert(parseJsonToResponse(result.data, modelProvider));
      context.res.contentType ??= ContentType.json;
    }
    if (modelProvider?.toJsonModels.containsKey(result.data.runtimeType) ?? false) {
      responseData = JsonUtf8Encoder().convert(modelProvider?.to(result.data));
      context.res.contentType ??= ContentType.json;
    }
    if (result.data is Uint8List) {
      context.res.contentType ??= ContentType.binary;
    }
    result.data = responseData ?? result.data;
    return result;
  }
  
  Future<void> _handleMiddlewares(
    RouteContext context,
    RequestContext requestContext,
    Iterable<Middleware> middlewares,
    OutcomingMessage response,
    IncomingMessage request,
  ) async {
    final completer = Completer<void>();
    if (middlewares.isEmpty) {
      return;
    }
    for (int i = 0; i < middlewares.length; i++) {
      final middleware = middlewares.elementAt(i);
      await middleware.use(requestContext, ([data]) async {
        if (data != null) {
          final responseData = WrappedResponse(data);
          _executeOnResponse(
            context,
            requestContext,
            responseData,
          );
          data = _processResult(responseData, requestContext);
          request.emit(
            RequestEvent.data,
            EventData(data: data, properties: requestContext.res),
          );
          await _responseController.sendResponse(
            response,
            data,
            requestContext.res,
            viewEngine: viewEngine,
          );
          request.emit(
            RequestEvent.close,
            EventData(
                data: data,
                properties: requestContext.res
                  ..headers.addAll(response.currentHeaders.toMap())),
          );
          return;
        }
        if (i == middlewares.length - 1) {
          completer.complete();
        }
      });
      if (response.isClosed && !completer.isCompleted) {
        completer.complete();
        break;
      }
    }
    return completer.future;
  }

  Future<void> _executeOnResponse(
    RouteContext context,
    RequestContext requestContext,
    WrappedResponse responseData,
  ) async {
    for (final hook in context.hooksContainer.resHooks) {
      await hook.onResponse(requestContext.request, responseData, requestContext.res);
    }
  }

  dynamic _resolveBody(
    dynamic body,
    RequestContext context,
  ) {
    if (body == null) {
      return null;
    }
    if (body == String) {
      if (context.body is! StringBody) {
        throw PreconditionFailedException('The body is not a string');
      }
      return context.body.value;
    }
    if ((('$body'.startsWith('Map') || '$body'.contains('List<Map')) &&
            '$body'.endsWith('>')) ||
        '$body' == 'Map') {
      if (context.body is! JsonBody) {
        throw PreconditionFailedException('The body is not a json');
      }
      return context.body.value;
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
        if (context.body is FormDataBody) {
          return modelProvider!.from(body, {
            ...context.body.value.fields,
            ...Map<String, dynamic>.fromEntries(context
                .body.value.files.entries
                .map((e) => MapEntry(e.key, e.value.toJson()))),
          });
        }
        if (context.body is JsonBody) {
          if (context.body is JsonList) {
            return context.body.value
                .map((e) => modelProvider!.from(body, e))
                .toList();
          } else {
            return modelProvider!.from(body, context.body.value);
          }
        }
      } catch (e) {
        throw PreconditionFailedException('The body cannot be converted to a valid model');
      }
    }
  }

}