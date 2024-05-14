import 'dart:async';

import '../http/internal_request.dart';
import '../http/internal_response.dart';

typedef RequestCallback = Future<void> Function(
    InternalRequest request, InternalResponse response);
typedef ErrorHandler = void Function(dynamic e, StackTrace stackTrace);

abstract class Adapter<TServer> {
  Adapter();

  TServer? server;

  Future<void> init();

  Future<void> close();

  Future<void> listen(
    covariant dynamic requestCallback, {
    InternalRequest request,
    ErrorHandler? errorHandler,
  });
}
