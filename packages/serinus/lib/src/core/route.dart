import 'dart:io';

import 'package:meta/meta.dart';
import '../commons/commons.dart';
import 'contexts/request_context.dart';

abstract class BodyTransformer{

  const BodyTransformer();

  Body call(Body rawBody, ContentType contentType);

}

abstract class Route {

  final String path;
  final HttpMethod method;
  final Map<String, Type> queryParameters;
  final BodyTransformer? bodyTranformer;

  const Route({
    required this.path,
    required this.method,
    this.queryParameters = const {},
    this.bodyTranformer
  });

}