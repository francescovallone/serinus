import 'dart:io';
import 'dart:typed_data';

import '../contexts/contexts.dart';
import '../core/application_config.dart';
import '../core/tracer.dart';
import '../engines/view_engine.dart';
import '../http/internal_response.dart';
import '../http/streamable_response.dart';

/// The [ResponseHandler] class is used to handle the response of a request.
class ResponseHandler{

  final InternalResponse response;
  final RequestContext context;
  final Object data;
  final ApplicationConfig config;
  final String? traced;

  bool get isView => data is View || data is ViewString;

  int get statusCode => context.res.statusCode;
  
  /// Creates a new instance of [ResponseHandler].
  ResponseHandler(
    this.response,
    this.context,
    this.data,
    this.config,
    this.traced,
  ) {
    if (isView && config.viewEngine == null) {
      throw StateError('ViewEngine is required to render views');
    }
  }

  Future<void> handle() async {
    await _startResponseHandling();
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
    response.contentType(context.res.contentType ?? 
        ContentType.text);
  }

  Future<void> _startResponseHandling() async {
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
