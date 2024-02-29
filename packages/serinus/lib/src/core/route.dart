import 'dart:io';

import 'package:meta/meta.dart';
import '../commons/commons.dart';
import 'contexts/request_context.dart';

abstract class BodyTransformer<T>{

  const BodyTransformer();

  T call(String rawBody, ContentType contentType);

}

abstract class Route {

  final String path;
  final HttpMethod method;
  final Map<String, Type> queryParameters;
  final BodyTransformer<Object>? body;

  const Route({
    required this.path,
    required this.method,
    this.queryParameters = const {},
    this.body
  });
  
  @mustBeOverridden
  Future<void> handle(RequestContext context, Response response);

}