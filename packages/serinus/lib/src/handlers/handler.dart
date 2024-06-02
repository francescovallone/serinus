import 'dart:convert';

import '../containers/module_container.dart';
import '../containers/router.dart';
import '../contexts/request_context.dart';
import '../core/core.dart';
import '../exceptions/exceptions.dart';
import '../http/http.dart';
import '../http/internal_request.dart';

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
    if (request.method == 'OPTIONS') {
      await config.cors?.call(request, Request(request), null, null);
      return;
    }
    try {
      await handleRequest(request, response);
    } on SerinusException catch (e) {
      response.headers(config.cors?.responseHeaders ?? {});
      response.status(e.statusCode);
      return response.send(utf8.encode(e.toString()));
    }
  }

  /// Handles the request and sends the response
  ///
  /// This is the method to be implemented by the handler
  Future<void> handleRequest(
      InternalRequest request, InternalResponse response);

  /// Build the request context from the request and body
  RequestContext buildRequestContext(
      Iterable<Provider> providers, Request request, Body body) {
    RequestContextBuilder builder = RequestContextBuilder(providers: {
      for (final provider in providers) provider.runtimeType: provider
    });
    return builder.build(request, body);
  }
}
