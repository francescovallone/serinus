import 'package:grpc/grpc.dart';
import 'package:serinus/serinus.dart';

/// The [GrpcServiceController] allows defining gRPC services as Serinus Controllers.
///
/// It extends the base [Controller] class and includes a reference to the gRPC [Service] it represents. This controller can be used to group related gRPC methods together, making it easier to manage and organize your gRPC services within the Serinus framework.
class GrpcServiceController extends Controller {
  /// The [service] property contains the gRPC service definition that this controller represents.
  final Service service;

  /// Creates a gRPC service controller.
  GrpcServiceController({
    required this.service,
  }) : super(service.$name);
}
