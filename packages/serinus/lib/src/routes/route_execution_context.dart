import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import '../../serinus.dart';
import '../adapters/adapters.dart';
import '../contexts/contexts.dart';
import '../contexts/route_context.dart';
import '../exceptions/exceptions.dart';
import '../extensions/object_extensions.dart';
import '../http/http.dart';
import '../services/json_utils.dart';
import 'route_response_controller.dart';

class RouteExecutionContext {
  
  final RouteResponseController _responseController;

  final ModelProvider? modelProvider;

  final ViewEngine? viewEngine;

  RouteExecutionContext(this._responseController, {this.modelProvider, this.viewEngine});

  Future<Function> describe(
    RouteContext context,
    Map<String, dynamic> params,
    {
      ErrorHandler? errorHandler,
      NotFoundHandler? notFoundHandler,
    }
  ) async {
    return (InternalRequest request, InternalResponse response) async {
      final currentProperties = ResponseProperties();
      final wrappedRequest = Request(request, params);
      for (final hook in context.hooksContainer.reqHooks) {
        await hook.onRequest(wrappedRequest, currentProperties);
        if (currentProperties.closed) {
          await _responseController.sendResponse(response, null, currentProperties, viewEngine: viewEngine);
          return;
        }
      }
      final requestContext = RequestContext.fromRouteContext(wrappedRequest, context);
      requestContext.metadata = await context.initMetadata(requestContext);
      requestContext.body = _resolveBody(requestContext.body.value, requestContext) ?? requestContext.body.value;
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
      final middlewares =
        context.getMiddlewares(wrappedRequest.params);
      if (middlewares.isNotEmpty) {
        await handleMiddlewares(requestContext, middlewares, response, request);
        if (response.isClosed) {
          return;
        }
      }
      
    };
  }

  Object? _processResult(
      Object? result, RequestContext context) {
    if (result?.canBeJson() ?? false) {
      result =
          JsonUtf8Encoder().convert(parseJsonToResponse(result, modelProvider));
      context.res.contentType ??= ContentType.json;
    }
    if (modelProvider?.toJsonModels.containsKey(result.runtimeType) ?? false) {
      result = JsonUtf8Encoder().convert(modelProvider?.to(result));
      context.res.contentType ??= ContentType.json;
    }
    if (result is Uint8List) {
      context.res.contentType ??= ContentType.binary;
    }
    return result;
  }

  /// Handles the middlewares
  ///
  /// If the completer is not completed, the request will be blocked until the completer is completed.
  Future<void> handleMiddlewares(
    RequestContext context,
    Iterable<Middleware> middlewares,
    InternalResponse response,
    InternalRequest request,
  ) async {
    final completer = Completer<void>();
    if (middlewares.isEmpty) {
      return;
    }
    for (int i = 0; i < middlewares.length; i++) {
      final middleware = middlewares.elementAt(i);
      await middleware.use(context, ([data]) async {
        if (data != null) {
          data = _processResult(data, context);
          request.emit(
            RequestEvent.data,
            EventData(data: data, properties: context.res),
          );
          await _responseController.sendResponse(
            response,
            data,
            context.res,
            viewEngine: viewEngine,
          );
          request.emit(
            RequestEvent.close,
            EventData(
                data: data,
                properties: context.res
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

  dynamic _resolveBody(
    dynamic body,
    RequestContext context,
  ) {
    if (body == null) {
      return null;
    }
    if (body == String) {
      if (context.body.text == null) {
        throw PreconditionFailedException('The body is not a string');
      }
      return context.body.text;
    }
    if ((('$body'.startsWith('Map') || '$body'.contains('List<Map')) &&
            '$body'.endsWith('>')) ||
        '$body' == 'Map') {
      if (context.body.json == null) {
        throw PreconditionFailedException('The body is not a json');
      }
      return context.body.json!.value;
    }
    if (body == Uint8List) {
      if (context.body.bytes == null) {
        throw PreconditionFailedException('The body is not a binary');
      }
      return context.body.bytes;
    }
    if (body == FormData) {
      if (context.body.formData == null) {
        throw PreconditionFailedException('The body is not a form data');
      }
      return context.body.formData;
    }
    if (modelProvider != null) {
      try {
        if (context.body.formData != null) {
          return modelProvider!.from(body, {
            ...context.body.formData!.fields,
            ...Map<String, dynamic>.fromEntries(context
                .body.formData!.files.entries
                .map((e) => MapEntry(e.key, e.value.toJson()))),
          });
        }
        if (context.body.json != null) {
          if (context.body.json!.multiple) {
            return context.body.json!.value
                .map((e) => modelProvider!.from(body, e))
                .toList();
          } else {
            return modelProvider!.from(body, context.body.json!.value);
          }
        }
      } catch (e) {
        throw PreconditionFailedException('The body cannot be converted to a valid model');
      }
    }
  }

}