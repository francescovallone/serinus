import 'dart:convert';
import 'dart:io';

import '../adapters/adapters.dart';
import '../containers/module_container.dart';
import '../containers/router.dart';
import '../contexts/request_context.dart';
import '../core/core.dart';
import '../enums/enums.dart';
import '../exceptions/exceptions.dart';
import '../http/http.dart';

/// The base class for all handlers in the application
abstract class Handler {
  /// The instance of the router currently used by the application
  final Router router;

  /// The instance of the modules container currently used by the application
  final ModulesContainer modulesContainer;

  /// The current configuration of the application
  final ApplicationConfig config;

  /// Creates a new instance of the handler
  const Handler(this.router, this.modulesContainer, this.config);

  /// Handles the request and sends the response
  /// This method is responsible for handling the request.
  Future<void> handle(
      InternalRequest request, InternalResponse response) async {
    try {
      await handleRequest(request, response);
    } on SerinusException catch (e) {
      final exception = e.copyWith(
        uri: e.uri ?? request.uri,
        statusCode: e.statusCode,
      );
      final error = utf8.encode(jsonEncode(exception.toJson()));
      final currentContext = buildRequestContext(
        [],
        Request(request),
        response,
      );
      request.emit(
        RequestEvent.error,
        EventData(
          data: exception.toJson(),
          properties: currentContext.res,
          exception: exception,
        ),
      );
      currentContext.res.statusCode = exception.statusCode;
      currentContext.res.contentType = ContentType.json;
      for (final hook in config.hooks.exceptionHooks) {
        await hook.onException(currentContext, exception);
      }
      config.adapters.get<HttpAdapter>('http').reply(
        response,
        error,
        currentContext,
        config,
      );
      return;
    }
  }

  /// Handles the request and sends the response
  ///
  /// This is the method to be implemented by the handler
  Future<void> handleRequest(
      InternalRequest request, InternalResponse response);

  /// Build the request context from the request and body
  RequestContext buildRequestContext(Iterable<Provider> providers,
      Request request, InternalResponse response) {
    return RequestContext(
      {for (final provider in providers) provider.runtimeType: provider},
      config.hooks.services,
      request,
      StreamableResponse(response),
    );
  }
}
