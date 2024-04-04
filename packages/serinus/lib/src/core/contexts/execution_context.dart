import 'package:serinus/serinus.dart';

sealed class ExecutionContext {
  final Map<Type, Provider> providers;
  final Map<String, String> pathParameters;
  final Map<String, dynamic> queryParameters;
  final String path;
  final Map<String, dynamic> headers;
  final Request _request;
  late final Body body;

  ExecutionContext(
    this.providers,
    this.pathParameters,
    this.queryParameters,
    this.headers,
    this.path,
    this._request
  );

  T use<T>(){
    if(!providers.containsKey(T)){
      throw StateError('Provider not found in request context');
    }
    return providers[T] as T;
  }

  void addDataToRequest(String key, dynamic value){
    _request.addData(key, value);
  }

}

class _ExecutionContextImpl extends ExecutionContext {

  _ExecutionContextImpl(
    Map<Type, Provider> providers,
    Map<String, String> pathParameters,
    Map<String, dynamic> queryParameters,
    Map<String, dynamic> headers,
    String path,
    Request request
  ) : super(
    providers,
    pathParameters,
    queryParameters,
    headers,
    path,
    request
  );

  @override
  T use<T>() {
    if(!providers.containsKey(T)){
      throw StateError('Provider not found in request context');
    }
    return providers[T] as T;
  }

}

class ExecutionContextBuilder {

  final Map<Type, Provider> providers = {};
  final Map<String, String> pathParameters = {};
  final Map<String, dynamic> queryParameters = {};
  final Map<String, dynamic> headers = {};
  late String path;
  late Body body;

  ExecutionContextBuilder addProviders(Iterable<Provider> providers){
    this.providers.addAll({
      for (var provider in providers) provider.runtimeType: provider,
    });
    return this;
  }

  ExecutionContextBuilder addPathParameters(
    String routePath,
    String requestPath
  ){
    final pathParameters = <String, String>{};
    final routePathSegments = routePath.split('/');
    final requestPathSegments = requestPath.split('/');
    for (var i = 0; i < routePathSegments.length; i++) {
      if(routePathSegments[i].startsWith(':')){
        pathParameters[routePathSegments[i].substring(1)] = requestPathSegments[i];
      }
    }
    this.pathParameters.addAll(pathParameters);
    return this;
  }

  ExecutionContextBuilder addQueryParameters(Map<String, Type> queryParametersRoute, Map<String, String> queryParametersRequest){
    final queryParameters = <String, dynamic>{};
    queryParametersRequest.forEach((key, value) {
      switch(queryParametersRoute[key]){
        case int:
          queryParameters[key] = int.parse(value);
          break;
        case double:
          queryParameters[key] = double.parse(value);
          break;
        case bool:
          queryParameters[key] = value.toLowerCase() == 'true';
          break;
        default:
          queryParameters[key] = value;
      }
    });
    this.queryParameters.addAll(queryParameters);
    return this;
  }

  ExecutionContextBuilder addHeaders(Map<String, dynamic> headers){
    this.headers.addAll(headers);
    return this;
  }

  ExecutionContextBuilder setPath(String path){
    this.path = path;
    return this;
  }

  ExecutionContextBuilder setBody(Body body){
    this.body = body;
    return this;
  }

  ExecutionContext build(Request request){
    return _ExecutionContextImpl(
      providers,
      pathParameters,
      queryParameters,
      headers,
      path,
      request
    )..body = body;
  }
}