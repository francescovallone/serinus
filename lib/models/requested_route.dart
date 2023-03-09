import 'dart:mirrors';

import 'package:mug/commons/commons.dart';
import 'package:mug/commons/middleware/middleware_consumer.dart';
import 'package:mug/exceptions/exceptions.dart';
import 'package:mug/models/models.dart';
import 'package:mug/mug.dart';
import 'package:mug/request.dart';
import 'package:mug/utils/utils.dart';

class RequestedRoute{

  final RouteData data;
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

  void execute(){
    InstanceMirror? result;
    if(data.module is MugModule){
      Symbol configure = MugContainer.instance.getMiddlewareConsumer(data.module);
      if(Symbol.empty != configure){
        InstanceMirror moduleInstance = reflect(data.module);
        MiddlewareConsumer consumer = MiddlewareConsumer();
        moduleInstance.invoke(configure, [consumer]);
        if(!consumer.excludedRoutes.any((element) => (
            (
              (element.method != null && element.method == data.method) || element.method == null) 
              && (element.uri.path == data.path || element.uri.path == "*")
            )
          )
        ){
          consumer.middleware.use(_request, _response, ()  {
            result = invoke();
          });
        }
      }
    }
    if(result == null){
      result = invoke();
    }
    _response.setData(result!.reflectee);
  }

  InstanceMirror invoke(){
    return data.controller.invoke(
      data.symbol, 
      params.values.toList()
    );
  }

}