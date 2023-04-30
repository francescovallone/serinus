import 'dart:mirrors';

import 'package:serinus/serinus.dart';
import 'package:serinus/src/core/core.dart';
import 'package:serinus/src/models/models.dart';

class RequestContext{

  final RouteContext data;
  Map<String, dynamic> params;
  late Request _request;
  late Response _response;

  RequestContext({
    required this.data,
    required this.params
  });

  Future<void> init(Request request, Response response) async {
    if(params.isEmpty){
      throw BadRequestException(uri: Uri.parse(data.path));
    }
    params = await SerinusContainer.instance.addParameters(
      params, 
      request, 
      data
    );
    _request = request;
    _response = response;
  }

  Future<void> handle() async {
    InstanceMirror? result = _consumeMiddlewares();
    if(result == null){
      result = invoke();
    }
    _response.data = result.reflectee;
    await _response.sendData();
  }

  InstanceMirror? _consumeMiddlewares(){
    InstanceMirror? result;
    for(MiddlewareConsumer consumer in data.middlewares){
      consumer.middleware?.use(
        _request, 
        _response, 
        consumer == data.middlewares.last 
          ? () {
            result = invoke();
          } 
          : () => {}
      );
    }
    return result;
  }

  InstanceMirror invoke(){
    return data.controller.invoke(
      data.symbol, 
      params.values.toList()
    );
  }



}