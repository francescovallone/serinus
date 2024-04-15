import 'package:serinus/serinus.dart';


sealed class RequestContext {

  final Map<Type, Provider> providers;
  final Map<String, dynamic> pathParameters;
  final Map<String, dynamic> queryParameters;
  final String path;
  late final Body body;

  RequestContext(
    this.providers,
    this.pathParameters,
    this.queryParameters,
    this.path
  );

  T use<T>(){
    if(!providers.containsKey(T)){
      throw StateError('Provider not found in request context');
    }
    return providers[T] as T;
  }

}

class _RequestContextImpl extends RequestContext {

  _RequestContextImpl(
    Map<Type, Provider> providers,
    Map<String, dynamic> pathParameters,
    Map<String, dynamic> queryParameters,
    String path
  ) : super(
    providers,
    pathParameters,
    queryParameters,
    path
  );

  @override
  T use<T>() {
    if(!providers.containsKey(T)){
      throw StateError('Provider not found in request context');
    }
    return providers[T] as T;
  }

}

class RequestContextBuilder {

  RequestContext? _context;

  Map<Type, Provider> providers = {};
  Map<String, dynamic> pathParameters = {};
  Map<String, dynamic> queryParameters = {};
  String path = '';

  RequestContextBuilder();

  RequestContextBuilder addProviders(Iterable<Provider> providers){
    this.providers.addAll({
      for (var provider in providers) provider.runtimeType: provider,
    });
    return this;
  }

  RequestContextBuilder addPathParameters(
    Map<String, dynamic> params

  ){
    this.pathParameters.addAll(params);
    return this;
  }
  
  RequestContextBuilder addQueryParameters(Map<String, Type> queryParametersRoute, Map<String, String> queryParametersRequest){
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

  RequestContextBuilder setPath(String path){
    this.path = path;
    return this;
  }

  RequestContext build(){
    _context = _RequestContextImpl(
      providers,
      pathParameters,
      queryParameters,
      path
    );
    return _context!;
  }

}