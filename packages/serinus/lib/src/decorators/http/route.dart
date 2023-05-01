import 'package:serinus/serinus.dart';

abstract class Route{

  final String path;
  final Method method;
  final int statusCode;

  const Route(this.path, {this.method = Method.get, this.statusCode = 200});

}
