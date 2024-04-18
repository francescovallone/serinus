import 'dart:io';

import 'package:serinus/src/core/pipe.dart' as p;

import '../commons/commons.dart';
import 'guard.dart';

abstract class BodyTransformer{

  const BodyTransformer();

  Body call(Body rawBody, ContentType contentType);

}

abstract class Route {

  final String path;
  final HttpMethod method;
  final Map<String, Type> queryParameters;
  final BodyTransformer? bodyTranformer;

  List<Guard> get guards => [];
  List<p.Pipe> get pipes => [];

  const Route({
    required this.path,
    required this.method,
    this.queryParameters = const {},
    this.bodyTranformer,
  });

}