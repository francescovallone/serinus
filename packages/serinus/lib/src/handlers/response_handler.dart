import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:http_parser/http_parser.dart';

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
      late String rendered;
      if (data is View) {
        rendered = await config.viewEngine!.render(data);
      } else if (data is ViewString) {
        rendered = await config.viewEngine!.renderString(data);
      }
      responseBody = utf8.encode(rendered);
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
    await config.tracerService.addSyncEvent(
      name: TraceEvents.onResponse,
      request: context.request,
      context: context,
      traced: traced ?? context.request.id,
    );
    response.headers({
      ...context.res.headers,
      HttpHeaders.contentLengthHeader: responseBody.length.toString()
    });
    return response.send(responseBody);
  }

  Uint8List _convertData(Object data, bool isView, Uint8List responseBody) {
    if (data.isPrimitive()) {
      responseBody = utf8.encode(data.toString());
    } else if (data is Uint8List) {
      responseBody = data;
    } else if (!isView) {
      responseBody = utf8.encode(jsonEncode(data));
    }
    final coding = response.currentHeaders['transfer-encoding']?.join(';');
    if (coding != null && !equalsIgnoreAsciiCase(coding, 'identity')) {
      responseBody = Uint8List.fromList(chunkedCoding.decoder.convert(responseBody.toList()));
      response.headers({HttpHeaders.transferEncodingHeader: 'chunked'});
    } else if (statusCode >=
            200 &&
        statusCode != 204 &&
        statusCode != 304 &&
        context.res.contentLength == null &&
        context.res.contentType?.mimeType !=
            'multipart/byteranges') {
      response.headers({HttpHeaders.transferEncodingHeader: 'chunked'});
    }
    return responseBody;
  }

  Future<void> _startResponseHandling(Object data) async {
    config.tracerService.addEvent(
      name: TraceEvents.onResponse,
      begin: true,
      request: context.request,
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
