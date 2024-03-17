
import 'dart:async';

import '../internal_request.dart';
import '../internal_response.dart';

typedef RequestCallback = Future<void> Function(InternalRequest request, InternalResponse response);
typedef ErrorHandler = void Function(dynamic e, StackTrace stackTrace);

abstract class HttpServerAdapter<TServer> {

  TServer? server;

  FutureOr<void> init({
    String host = 'localhost',
    int port = 3000,
    String poweredByHeader = 'Powered by Serinus',
  });

  FutureOr<void> close();

  FutureOr<void> listen(
    RequestCallback requestCallback,
    {
      ErrorHandler? errorHandler
    }
  );

}