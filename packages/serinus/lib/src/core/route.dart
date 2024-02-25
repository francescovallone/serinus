import 'package:meta/meta.dart';
import 'package:serinus/src/commons.dart';
import 'package:serinus/src/commons/request.dart';

abstract class Route {

  final String path;
  final HttpMethod method;

  const Route({
    required this.path,
    required this.method,
  });
  
  @mustBeOverridden
  Future<void> handle(InternalRequest request, Response response);

}