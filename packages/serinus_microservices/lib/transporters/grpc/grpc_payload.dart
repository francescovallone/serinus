import 'package:grpc/grpc.dart';

/// The [GrpcPayload] class carries metadata and request stream for gRPC handlers.
sealed class GrpcPayload<F, Q, R> {
  /// The gRPC service call.
  final ServiceCall call;

  /// The raw incoming request representation (future or stream).
  final F futureRequest;

  /// The gRPC service method metadata.
  final ServiceMethod<Q, R> method;

  /// The gRPC invoker used to call the underlying service.
  final ServerStreamingInvoker<Q, R> invoker;

  /// Creates a gRPC payload.
  GrpcPayload(
    this.call,
    this.futureRequest, {
    required this.method,
    required this.invoker,
  });

  /// True when the request is streaming.
  bool get streamingRequest => method.streamingRequest;

  /// True when the response is streaming.
  bool get streamingResponse => method.streamingResponse;

  /// Resolves the incoming request into the request type expected by the service.
  dynamic getRequest();

  /// Invokes the underlying service method using the invoker.
  Stream<R> invoke(Stream<Q> requests) {
    return invoker(call, method, requests);
  }

  /// Casts an incoming stream to the expected request type.
  Stream<Q> coerceStream(Stream<dynamic> input) => input.cast<Q>();

  /// Casts a single value to the expected request type.
  Q coerceSingle(dynamic value) => value as Q;
}

/// The [GrpcPayloadUnitary] class is the gRPC unary payload.
class GrpcPayloadUnitary<Q, R> extends GrpcPayload<Future<Q>, Q, R> {
  /// Creates a gRPC unary payload.
  GrpcPayloadUnitary(
    ServiceCall call,
    Future<Q> futureRequest, {
    required super.method,
    required super.invoker,
  }) : super(call, futureRequest);

  Q? _request;

  @override
  Future<Q> getRequest() async {
    if (_request != null) {
      return _request!;
    }
    _request = await futureRequest;
    return _request!;
  }
}

/// The [GrpcPayloadStream] class is the gRPC stream payload.
class GrpcPayloadStream<Q, R> extends GrpcPayload<Stream<Q>, Q, R> {
  /// Creates a gRPC stream payload.
  GrpcPayloadStream(
    ServiceCall call,
    Stream<Q> futureRequest, {
    required super.method,
    required super.invoker,
  }) : super(call, futureRequest);

  @override
  Stream<Q> getRequest() async* {
    yield* futureRequest;
  }
}
