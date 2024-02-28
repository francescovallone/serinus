import 'package:meta/meta.dart';
import '../commons/commons.dart';
import 'contexts/request_context.dart';

abstract class Route {

  final String path;
  final HttpMethod method;
  final Map<String, Type> queryParameters;

  const Route({
    required this.path,
    required this.method,
    this.queryParameters = const {},
  });
  
  @mustBeOverridden
  Future<void> handle(RequestContext context, Response response);

}