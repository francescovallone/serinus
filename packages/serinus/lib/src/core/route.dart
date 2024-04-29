import 'package:serinus/src/core/pipe.dart' as p;

import '../commons/commons.dart';
import 'guard.dart';

abstract class Route {

  final String path;
  final HttpMethod method;
  final Map<String, Type> queryParameters;

  List<Guard> get guards => [];
  List<p.Pipe> get pipes => [];

  const Route({
    required this.path,
    required this.method,
    this.queryParameters = const {},
  });

}