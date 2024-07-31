import '../containers/module_container.dart';
import '../core/core.dart';
import '../http/internal_request.dart';
import 'server_adapter.dart';

/// The [RequestCallback] type is used to define the request callback.
abstract class HttpAdapter<TServer> extends Adapter<TServer> {
  /// The [host] property contains the host of the server.
  final String host;

  /// The [port] property contains the port of the server.
  final int port;

  /// The [poweredByHeader] property contains the powered by header.
  final String poweredByHeader;

  /// The [HttpAdapter] constructor is used to create a new instance of the [HttpAdapter] class.
  HttpAdapter(
      {required this.host, required this.port, required this.poweredByHeader});

  @override
  Future<void> init(ModulesContainer container, ApplicationConfig config);

  @override
  Future<void> close();

  @override
  Future<void> listen(RequestCallback requestCallback,
      {InternalRequest? request, ErrorHandler? errorHandler});
}
