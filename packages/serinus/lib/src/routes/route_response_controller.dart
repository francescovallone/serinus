
import '../../serinus.dart';
import '../adapters/adapters.dart';

class RouteResponseController {

  final HttpAdapter _applicationRef;

  const RouteResponseController(this._applicationRef);

  Future<void> sendResponse<TResponse, TData>(TResponse response, TData data, ResponseProperties properties, {ViewEngine? viewEngine}) async {
    await _applicationRef.reply(
      response,
      data,
      properties,
    );
  }

  Future<void> redirect<TResponse>(TResponse response, Redirect redirect, ResponseProperties properties) async {
    await _applicationRef.redirect(response, redirect, properties);
  }

  Future<void> render<TResponse>(TResponse response, View view, ResponseProperties properties) async {
    return _applicationRef.render(
      response,
      view,
      properties,
    );
  }

}