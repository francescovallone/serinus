import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:collection/collection.dart';

import '../contexts/contexts.dart';
import '../core/application_config.dart';
import '../core/tracer.dart';
import '../engines/view_engine.dart';
import '../extensions/object_extensions.dart';
import '../http/internal_response.dart';
import '../http/streamable_response.dart';

/// The [ResponseHandler] class is used to handle the response of a request.
class ResponseHandler{

  /// The [InternalResponse] object.
  final InternalResponse response;
  /// The [RequestContext] of the request.
  final RequestContext context;
  /// The [ApplicationConfig] object.
  final ApplicationConfig config;
  /// The traced id of the request.
  final String? traced;
  /// The status code of the response.
  int get statusCode => context.res.statusCode;
  
  /// Creates a new instance of [ResponseHandler].
  const ResponseHandler(
    this.response,
    this.context,
    this.config,
    this.traced,
  );

  /// This method is used to handle the response of a request.
  Future<void> handle(Object data) async {
    await _startResponseHandling(data);
    if (data is StreamedResponse) {
      await response.flushAndClose();
      return;
    }
    final resRedirect = context.res.redirect;
    if (resRedirect != null) {
      response.headers({
        HttpHeaders.locationHeader: resRedirect.location,
        ...context.res.headers
      });
      return response.redirect(resRedirect.location, resRedirect.statusCode);
    }
    response.status(statusCode);
    response.headers({
      ...context.res.headers,
      HttpHeaders.transferEncodingHeader: 'chunked'
    });
    Uint8List responseBody = Uint8List(0);
    response.contentType(
      context.res.contentType ?? ContentType.text
    );
    final isView = data is View || data is ViewString;
    if (isView && config.viewEngine == null) {
      throw StateError('ViewEngine is required to render views');
    }
    if (isView) {
      if (data is View) {
        data = await config.viewEngine!.render(data);
      } else if (data is ViewString) {
        data = await config.viewEngine!.renderString(data);
      }
      response.contentType(context.res.contentType ?? ContentType.html);
      response.headers({
        HttpHeaders.contentLengthHeader: responseBody.length.toString(),
      });
    }
    if (data is File) {
      response.contentType(
        context.res.contentType ?? ContentType.parse('application/octet-stream')
      );
      final readPipe = data.openRead();
      return response.sendStream(readPipe);
    }
    responseBody = _convertData(data, isView, responseBody);
    config.tracerService.addEvent(
      name: TraceEvents.onResponse,
      request: context.request,
      context: context,
      traced: traced ?? context.request.id,
    );
    await config.tracerService.endTrace(context.request);
    response.headers({
      ...context.res.headers,
      HttpHeaders.contentLengthHeader: responseBody.length.toString()
    });
    return response.send(responseBody);
  }

  Uint8List _convertData(Object data, bool isView, Uint8List responseBody) {
    if(data is! Uint8List) {
      if (data.runtimeType.isPrimitive()) {
        responseBody = data.toBytes();
      } else {
        responseBody = jsonEncode(data).toBytes();
      }
    } else {
      responseBody = data;
    }
    final coding = response.currentHeaders['transfer-encoding']?.join(';');
    if (
      (
        coding != null && !equalsIgnoreAsciiCase(coding, 'identity')
      ) || (
        statusCode >= 200 &&
        statusCode != 204 &&
        statusCode != 304 &&
        context.res.contentLength == null &&
        context.res.contentType?.mimeType != 'multipart/byteranges'
      )
    ) {
      response.headers({HttpHeaders.transferEncodingHeader: 'chunked'});
    }
    return responseBody;
  }

  Future<void> _startResponseHandling(Object data) async {
    config.tracerService.addEvent(
      name: TraceEvents.onResponse,
      request: context.request,
      context: context,
      traced: traced ?? context.request.id,
    );
    for (final hook in config.hooks.reqResHooks) {
      await hook.onResponse(context.request, data, context.res);
    }
    response.cookies.addAll([
      ...context.res.cookies,
    ]);
  }

}
