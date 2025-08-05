
import '../adapters/adapters.dart';
import '../contexts/contexts.dart';
import '../engines/view_engine.dart';

/// The [RouteResponseController] class is used to handle responses for routes.
/// It provides methods to send responses, redirect, and render views.
class RouteResponseController {

  final HttpAdapter _applicationRef;

  /// The [RouteResponseController] constructor is used to create a new instance of the [RouteResponseController] class.
  const RouteResponseController(this._applicationRef);

  /// The [sendResponse] method is used to send a response to the client.
  Future<void> sendResponse<TResponse, TData>(TResponse response, TData data, ResponseContext properties, {ViewEngine? viewEngine}) async {
    await _applicationRef.reply(
      response,
      data,
      properties,
    );
  }

  /// The [redirect] method is used to redirect the response to a different URL.
  Future<void> redirect<TResponse>(TResponse response, Redirect redirect, ResponseContext properties) async {
    await _applicationRef.redirect(response, redirect, properties);
  }

  /// The [render] method is used to render a view.
  Future<void> render<TResponse>(TResponse response, View view, ResponseContext properties) async {
    return _applicationRef.render(
      response,
      view,
      properties,
    );
  }

}