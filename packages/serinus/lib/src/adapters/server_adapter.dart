import 'dart:async';

import '../http/internal_request.dart';
import '../http/internal_response.dart';

typedef RequestCallback = Future<void> Function(
    InternalRequest request, InternalResponse response);
typedef ErrorHandler = void Function(dynamic e, StackTrace stackTrace);

abstract class HttpServerAdapter<TServer> extends Adapter<TServer> {
  @override
  Future<void> init({
    String host = 'localhost',
    int port = 3000,
    String poweredByHeader = 'Powered by Serinus',
  });

  @override
  Future<void> close();

  @override
  Future<void> listen(RequestCallback requestCallback,
      {ErrorHandler? errorHandler});
}

abstract class Adapter<TServer> {
  TServer? server;

  Future<void> init({
    String host = 'localhost',
    int port = 3000,
  });

  Future<void> close();

  Future<void> listen(covariant dynamic requestCallback,
      {ErrorHandler? errorHandler});
}
