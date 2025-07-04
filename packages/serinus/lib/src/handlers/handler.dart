import 'dart:convert';
import 'dart:io';

import '../containers/module_container.dart';
import '../containers/router.dart';
import '../contexts/request_context.dart';
import '../core/core.dart';
import '../enums/enums.dart';
import '../exceptions/exceptions.dart';
import '../http/http.dart';
import 'response_handler.dart';

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
      final currentContext = buildRequestContext(
        [],
        Request(request),
        response,
      );
      SerinusException? editedException;
      for (final hook in config.hooks.exceptionHooks) {
        editedException = await hook.onException(currentContext, e);
      }
      final error = editedException ?? e;
      final encodedError =  utf8.encode(jsonEncode(e.toJson()));
      request.emit(
        RequestEvent.error,
        EventData(
          data: error.toJson(),
          properties: currentContext.res,
          exception: error,
        ),
      );
      currentContext.res.statusCode = error.statusCode;
      currentContext.res.contentType = ContentType.json;
      for (final hook in config.hooks.exceptionHooks) {
        await hook.onException(currentContext, error);
      }
      final resHandler =
          ResponseHandler(response, currentContext, config, null);
      await resHandler.handle(encodedError);
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
