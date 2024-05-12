import 'server_adapter.dart';

abstract class HttpAdapter<TServer> extends Adapter<TServer> {
  final String host;
  final int port;
  final String poweredByHeader;

  HttpAdapter(
      {required this.host, required this.port, required this.poweredByHeader});

  @override
  Future<void> init();

  @override
  Future<void> close();

  @override
  Future<void> listen(RequestCallback requestCallback,
      {ErrorHandler? errorHandler});
}
