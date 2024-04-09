
import 'dart:async';

import '../internal_request.dart';
import '../internal_response.dart';

typedef RequestCallback = Future<void> Function(InternalRequest request, InternalResponse response);
typedef ErrorHandler = void Function(dynamic e, StackTrace stackTrace);

abstract class HttpServerAdapter<TServer> {

  TServer? server;

  Future<void> init({
    String host = 'localhost',
    int port = 3000,
    String poweredByHeader = 'Powered by Serinus',
  });

  Future<void> close();

  Future<void> listen(
    RequestCallback requestCallback,
    {
      ErrorHandler? errorHandler
    }
  );

}