import 'dart:io';
import 'dart:typed_data';

import 'package:jaspr/server.dart' as jaspr;
import 'package:serinus/serinus.dart';
import 'package:shelf/shelf.dart' as shelf;

/// A Serinus [Controller] that bridges incoming requests to a Jaspr component.
///
/// It internally builds a Shelf handler via `serveApp` and registers a root
/// route (`/`) and a tail-wildcard route (`/**`) so that any request that
/// doesn't match a more-specific Serinus route is forwarded to the Jaspr
/// server-side rendering pipeline.
class JasprController extends Controller {
  /// The Shelf handler created from the Jaspr component.
  late final shelf.Handler _jasprHandler;

  /// Creates a new [JasprController].
  ///
  /// [component] is the root Jaspr component to render (typically a `Document`).
  /// [renderPath] is the base path under which the Jaspr app is served (default `/`).
  JasprController(
    jaspr.Component component, {
    String renderPath = '/',
  }) : super(renderPath) {
    // Build the Shelf handler from the Jaspr component.
    _jasprHandler = jaspr.serveApp((request, render) {
      return render(component);
    });

    // Match the exact base path (e.g. `/`).
    on(Route(path: '/', method: HttpMethod.all), _handleJaspr);
    // Match everything beneath the base path.
    on(Route(path: '/**', method: HttpMethod.all), _handleJaspr);
  }

  /// Forwards the Serinus request to the Jaspr Shelf handler and translates
  /// the Shelf response back into Serinus response properties.
  Future<Uint8List> _handleJaspr(RequestContext context) async {
    final shelfResponse = await _forwardToShelf(context.request);

    // Transfer status code.
    context.response.statusCode = shelfResponse.statusCode;

    // Transfer content type.
    final contentTypeHeader = shelfResponse.headers['content-type'];
    if (contentTypeHeader != null) {
      context.response.contentType = ContentType.parse(contentTypeHeader);
    }

    // Transfer remaining headers.
    final headers = Map<String, String>.from(shelfResponse.headers)
      ..remove('content-type');
    if (headers.isNotEmpty) {
      context.response.addHeaders(headers);
    }

    // Read full body as bytes.
    final bodyChunks = await shelfResponse.read().toList();
    final bytes = BytesBuilder();
    for (final chunk in bodyChunks) {
      bytes.add(chunk);
    }
    return bytes.takeBytes();
  }

  /// Converts a Serinus [Request] into a Shelf [shelf.Request], calls the
  /// handler, and returns the Shelf [shelf.Response].
  Future<shelf.Response> _forwardToShelf(Request request) async {
    final headers = request.headers.asFullMap();
    final shelfRequest = shelf.Request(
      request.method.name,
      request.uri,
      headers: headers,
    );
    return await _jasprHandler(shelfRequest);
  }
}
