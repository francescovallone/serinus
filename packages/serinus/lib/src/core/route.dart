
import '../enums/http_method.dart';
import 'guard.dart';
import 'pipe.dart';

abstract class Route {
  final String path;
  final HttpMethod method;
  final Map<String, Type> queryParameters;

  List<Guard> get guards => [];
  List<Pipe> get pipes => [];

  int? get version => null;

  const Route({
    required this.path,
    required this.method,
    this.queryParameters = const {},
  });
}
