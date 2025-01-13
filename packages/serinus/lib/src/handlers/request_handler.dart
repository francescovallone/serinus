import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import '../contexts/contexts.dart';
import '../core/core.dart';
import '../enums/enums.dart';
import '../exceptions/exceptions.dart';
import '../extensions/iterable_extansions.dart';
import '../extensions/object_extensions.dart';
import '../http/http.dart';
import '../mixins/mixins.dart';
import '../services/json_utils.dart';
import 'handler.dart';

/// The [RequestHandler] class is used to handle the HTTP requests.
class RequestHandler extends Handler {
  /// The [RequestHandler] constructor is used to create a new instance of the [RequestHandler] class.
  const RequestHandler(super.router, super.modulesContainer, super.config);

  /// Handles the request and sends the response
  ///
  /// This method is responsible for handling the request and sending the response.
  /// It will get the route data from the [RoutesContainer] and then it will get the controller
  /// from the [ModulesContainer]. Then it will get the route from the controller and execute the
  /// route handler. It will also execute the middlewares and guards.
  ///
  /// Request lifecycle:
  ///
  /// 1. Incoming request
  /// 2. [Middleware]s execution
  /// 4. [Route] handler execution
  /// 5. [Hook]s execution
  /// 6. Outgoing response
  @override
  Future<void> handleRequest(
      InternalRequest request, InternalResponse response) async {
    final Request wrappedRequest = Request(request);
    await wrappedRequest.parseBody();
    await config.tracerService.addSyncEvent(
        name: TraceEvents.onRequestReceived,
        request: wrappedRequest,
        traced: 'RequestHandler');
    await executeOnRequest(wrappedRequest, response);
    if (response.isClosed) {
      return;
    }

    final routeLookup = router.getRouteByPathAndMethod(
        request.path.endsWith('/')
            ? request.path.substring(0, request.path.length - 1)
            : request.path,
        request.method.toHttpMethod());
    final routeData = routeLookup.route;
    if (routeLookup.params.isNotEmpty) {
      wrappedRequest.params = routeLookup.params;
    }
    if (routeData == null) {
      throw NotFoundException(
          message:
              'No route found for path ${request.path} and method ${request.method}');
    }

    final injectables =
        modulesContainer.getModuleInjectablesByToken(routeData.moduleToken);
    final routeSpec = routeData.spec;
    final route = routeSpec.route;
    final handler = routeSpec.handler;
    final schema = routeSpec.schema;
    final scopedProviders =
        injectables.providers.addAllIfAbsent(modulesContainer.globalProviders);
    RequestContext context =
        buildRequestContext(scopedProviders, wrappedRequest, response);
    context.metadata = await _resolveMetadata(routeData.metadata, context);
    final body = getBodyValue(context, routeSpec.body);
    final bodyValue = body ?? context.body.value;
    if (route is OnTransform) {
      await executeOnTransform(context, route);
    }
    if (schema != null) {
      await executeOnParse(context, schema, route, bodyValue);
    }

    final middlewares = injectables.filterMiddlewaresByRoute(
        routeData.path, wrappedRequest.params);
    if (middlewares.isNotEmpty) {
      await handleMiddlewares(request, context, response, middlewares, config);
      if (response.isClosed) {
        return;
      }
    }
    await executeBeforeHandle(context, route);
    Object? result = await executeHandler(
        context, route, handler, routeData.isStatic, bodyValue, routeSpec.body);
    await executeAfterHandle(context, route, result);
    result = _processResult(result, context, config);
    if (context.res.redirect != null) {
      request.emit(
        RequestEvent.redirect,
        EventData(data: null, properties: context.res),
      );
    } else {
      request.emit(
        RequestEvent.data,
        EventData(data: result, properties: context.res),
      );
    }

    await response.end(
      data: result ?? 'null',
      config: config,
      context: context,
      traced: 'r-${route.runtimeType}',
    );

    request.emit(
      RequestEvent.close,
      EventData(
          data: result,
          properties: context.res
            ..headers.addAll(response.currentHeaders.toMap())),
    );
  }

  Future<Map<String, Metadata>> _resolveMetadata(
      List<Metadata> metadataList, RequestContext context) async {
    final Map<String, Metadata> metadata = {};
    for (final meta in metadataList) {
      if (meta is ContextualizedMetadata) {
        metadata[meta.name] = await meta.resolve(context);
      } else {
        metadata[meta.name] = meta;
      }
    }
    return metadata;
  }

  Object? _processResult(
      Object? result, RequestContext context, ApplicationConfig config) {
    if (result?.canBeJson() ?? false) {
      result = JsonUtf8Encoder()
          .convert(parseJsonToResponse(result, config.modelProvider));
      context.res.contentType = context.res.contentType ?? ContentType.json;
    }
    if (config.modelProvider?.toJsonModels.containsKey(result.runtimeType) ??
        false) {
      result = JsonUtf8Encoder().convert(config.modelProvider?.to(result));
      context.res.contentType = context.res.contentType ?? ContentType.json;
    }
    if (result is Uint8List) {
      context.res.contentType = context.res.contentType ?? ContentType.binary;
    }
    return result;
  }

  /// Handles the middlewares
  ///
  /// If the completer is not completed, the request will be blocked until the completer is completed.
  Future<void> handleMiddlewares(
      InternalRequest request,
      RequestContext context,
      InternalResponse response,
      Iterable<Middleware> middlewares,
      ApplicationConfig config) async {
    final completer = Completer<void>();
    if (middlewares.isEmpty) {
      return;
    }
    for (int i = 0; i < middlewares.length; i++) {
      config.tracerService.addEvent(
          name: TraceEvents.onMiddleware,
          begin: true,
          request: context.request,
          context: context,
          traced: 'm-${middlewares.elementAt(i).runtimeType}');
      final middleware = middlewares.elementAt(i);
      await middleware.use(context, ([data]) async {
        await config.tracerService.addSyncEvent(
            name: TraceEvents.onMiddleware,
            request: context.request,
            context: context,
            traced: 'm-${middlewares.elementAt(i).runtimeType}');
        if (data != null) {
          data = _processResult(data, context, config);
          request.emit(
            RequestEvent.data,
            EventData(data: data, properties: context.res),
          );
          await response.end(
              data: data!,
              config: config,
              context: context,
              traced: 'm-${middlewares.elementAt(i).runtimeType}');
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

  /// Executes the [onRequest] hooks
  Future<void> executeOnRequest(
      Request wrappedRequest, InternalResponse response) async {
    for (final hook in config.hooks.reqResHooks) {
      config.tracerService.addEvent(
          name: TraceEvents.onRequest,
          begin: true,
          request: wrappedRequest,
          traced: 'h-${hook.runtimeType}');
      if (response.isClosed) {
        return;
      }
      await hook.onRequest(wrappedRequest, response);
      await config.tracerService.addSyncEvent(
          name: TraceEvents.onRequest,
          request: wrappedRequest,
          traced: 'h-${hook.runtimeType}');
    }
  }

  /// Executes the [transform] hook from the route
  Future<void> executeOnTransform(
      RequestContext context, OnTransform route) async {
    config.tracerService.addEvent(
        name: TraceEvents.onTransform,
        request: context.request,
        begin: true,
        context: context,
        traced: 'r-${route.runtimeType}');
    await route.transform(context);
    await config.tracerService.addSyncEvent(
        name: TraceEvents.onTransform,
        request: context.request,
        context: context,
        traced: 'r-${route.runtimeType}');
  }

  /// Executes the [ParseSchema] from the route
  ///
  /// This method will parse the request body, query, params and headers.
  /// Also it will atomically add the parsed values to the request context.
  /// It means that if any of the values are not present in the request, they will not be added to the context.
  Future<void> executeOnParse(RequestContext context, ParseSchema schema,
      Route route, dynamic body) async {
    config.tracerService.addEvent(
        name: TraceEvents.onParse,
        begin: true,
        request: context.request,
        context: context,
        traced: 'r-${route.runtimeType}');
    final Map<String, dynamic> toParse = {};
    if (schema.body != null) {
      toParse['body'] = body;
    }
    if (schema.query != null) {
      toParse['query'] = context.request.query;
    }
    if (schema.params != null) {
      toParse['params'] = context.request.params;
    }
    if (schema.headers != null) {
      toParse['headers'] = context.request.headers;
    }
    if (schema.session != null) {
      toParse['session'] = context.request.session.all;
    }
    final result = await schema.tryParse(value: toParse);
    context.request.headers.addAll(result['headers'] ?? <String, String>{});
    context.request.params.addAll(result['params'] ?? {});
    context.request.query.addAll(result['query'] ?? {});
    await config.tracerService.addSyncEvent(
        name: TraceEvents.onParse,
        request: context.request,
        context: context,
        traced: 'r-${route.runtimeType}');
  }

  /// Executes the [beforeHandle] hook from the route
  Future<void> executeBeforeHandle(RequestContext context, Route route) async {
    for (final hook in config.hooks.beforeHooks) {
      config.tracerService.addEvent(
          name: TraceEvents.onBeforeHandle,
          begin: true,
          request: context.request,
          context: context,
          traced: 'h-${hook.runtimeType}');
      await hook.beforeHandle(context);
      await config.tracerService.addSyncEvent(
          name: TraceEvents.onBeforeHandle,
          request: context.request,
          context: context,
          traced: 'h-${hook.runtimeType}');
    }
    if (route is OnBeforeHandle) {
      config.tracerService.addEvent(
          name: TraceEvents.onBeforeHandle,
          begin: true,
          request: context.request,
          context: context,
          traced: 'r-${route.runtimeType}');
      await (route as OnBeforeHandle).beforeHandle(context);
      await config.tracerService.addSyncEvent(
          name: TraceEvents.onBeforeHandle,
          request: context.request,
          context: context,
          traced: 'r-${route.runtimeType}');
    }
  }

  /// Executes the [handler] from the route
  Future<Object?> executeHandler(RequestContext context, Route route,
      Object handler, bool isStatic, dynamic bodyValue, Type? body) async {
    config.tracerService.addEvent(
        name: TraceEvents.onHandle,
        begin: true,
        request: context.request,
        context: context,
        traced: 'r-${route.runtimeType}');
    Object? result;
    if (isStatic) {
      result = handler;
    }
    if (handler is Function) {
      if (handler is ReqResHandler) {
        result = await handler.call(context);
      } else {
        final bodyValue = getBodyValue(context, body);
        result = Function.apply(handler, [
          context,
          if (bodyValue != null) bodyValue,
          ...context.params.values
        ]);
        if (result is Future) {
          result = await result;
        }
      }
    }
    await config.tracerService.addSyncEvent(
        name: TraceEvents.onHandle,
        request: context.request,
        context: context,
        traced: 'r-${route.runtimeType}');
    return result;
  }

  /// Executes the [onAfterHandle] hook from the route
  Future<void> executeAfterHandle(
      RequestContext context, Route route, Object? result) async {
    if (route is OnAfterHandle) {
      config.tracerService.addEvent(
          name: TraceEvents.onAfterHandle,
          begin: true,
          request: context.request,
          context: context,
          traced: 'r-${route.runtimeType}');
      await (route as OnAfterHandle).afterHandle(context, result);
      await config.tracerService.addSyncEvent(
          name: TraceEvents.onAfterHandle,
          request: context.request,
          context: context,
          traced: 'r-${route.runtimeType}');
    }
    for (final hook in config.hooks.afterHooks) {
      config.tracerService.addEvent(
          name: TraceEvents.onAfterHandle,
          begin: true,
          request: context.request,
          context: context,
          traced: 'h-${hook.runtimeType}');
      await hook.afterHandle(context, result);
      await config.tracerService.addSyncEvent(
          name: TraceEvents.onAfterHandle,
          request: context.request,
          context: context,
          traced: 'h-${hook.runtimeType}');
    }
  }

  /// Get the body value from the request context or try to parse it with the model provider
  dynamic getBodyValue(RequestContext context, Type? body) {
    if (body == null) {
      return null;
    }
    if (body == String) {
      if (context.body.text == null) {
        throw PreconditionFailedException(message: 'The body is not a string');
      }
      return context.body.text;
    }
    if ((('$body'.startsWith('Map') || '$body'.contains('List<Map')) &&
            '$body'.endsWith('>')) ||
        '$body' == 'Map') {
      if (context.body.json == null) {
        throw PreconditionFailedException(message: 'The body is not a json');
      }
      return context.body.json!.value;
    }
    if (body == Uint8List) {
      if (context.body.bytes == null) {
        throw PreconditionFailedException(message: 'The body is not a binary');
      }
      return context.body.bytes;
    }
    if (body == FormData) {
      if (context.body.formData == null) {
        throw PreconditionFailedException(
            message: 'The body is not a form data');
      }
      return context.body.formData;
    }
    if (config.modelProvider != null) {
      try {
        if (context.body.formData != null) {
          return config.modelProvider!.from(body, {
            ...context.body.formData!.fields,
            ...Map<String, dynamic>.fromEntries(context
                .body.formData!.files.entries
                .map((e) => MapEntry(e.key, e.value.toJson()))),
          });
        }
        if (context.body.json != null) {
          if (context.body.json!.multiple) {
            return context.body.json!.value
                .map((e) => config.modelProvider!.from(body, e))
                .toList();
          } else {
            return config.modelProvider!.from(body, context.body.json!.value);
          }
        }
      } catch (e) {
        throw PreconditionFailedException(
            message: 'The body cannot be converted to a valid model');
      }
    }
  }
}
