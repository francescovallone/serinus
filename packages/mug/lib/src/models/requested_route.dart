import 'dart:mirrors';

import 'package:mug/src/mug_container.dart';

import 'package:mug/src/models/models.dart';
import 'package:mug/mug.dart';

class RequestedRoute{

  final RouteContext data;
  Map<String, dynamic> params;
  late Request _request;
  late Response _response;

  RequestedRoute({
    required this.data,
    required this.params
  });

  Future<void> init(Request request, Response response) async {
    if(params.isEmpty){
      throw BadRequestException(uri: Uri.parse(data.path));
    }
    params = await MugContainer.instance.addParameters(
      params, 
      request, 
      data
    );
    _request = request;
    _response = response;
  }

  Future<void> execute() async {
    InstanceMirror? result = _consumeMiddlewares();
    if(result == null){
      result = invoke();
    }
    _response.setData(result.reflectee);
    await _response.sendData();
  }

  InstanceMirror? _consumeMiddlewares(){
    InstanceMirror? result;
    if(data.module is MugModule){
      List<MiddlewareConsumer> consumers = MugContainer.instance.getMiddlewareConsumers(data.module);
      for(MiddlewareConsumer consumer in consumers){
        if(consumer.middleware != null && !consumer.excludedRoutes.any((element) => (
            (
              (element.method != null && element.method == data.method) || element.method == null) 
              && (element.uri.path == data.path || element.uri.path == "*")
            )
          )
        ){
          if(consumer == consumers.last){
            consumer.middleware!.use(_request, _response, ()  {
              result = invoke();
            });
          }else{
            consumer.middleware!.use(_request, _response, () => {});
          }
        }
      }
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