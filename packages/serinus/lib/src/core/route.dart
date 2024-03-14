import 'dart:io';

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

  const Route({
    required this.path,
    required this.method,
    this.queryParameters = const {},
    this.bodyTranformer,
  });

}