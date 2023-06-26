
import 'dart:mirrors';

import 'package:serinus/serinus.dart';
import 'package:serinus/src/models/models.dart';


Controller isController(InstanceMirror controller) {
  int index = controller.type.metadata.indexWhere((element) => element.reflectee is Controller);
  if(controller.reflectee is Controller){
    return controller.reflectee;
  }else if(index >= 0){
    return controller.type.metadata[index].reflectee;
  }else{
    throw StateError("${controller.type.reflectedType} is in the controllers list of the module but doesn't have the @Controller decorator");
  }
}

Map<String, dynamic> getRequestParameters(String element, Request request) {
  String requestPath = request.path;
  if(element == requestPath || element.substring(0, element.length - 1) == requestPath){
    return {element: true};
  }
  List<String> pathSegments = Uri(path: requestPath).pathSegments.where((element) => element.isNotEmpty).toList();
  List<String> elementSegments = Uri(path: element).pathSegments.where((element) => element.isNotEmpty).toList();
  if(pathSegments.length != elementSegments.length){
    return {};
  }
  Map<String, dynamic> pathParameters = {};
  for(int i = 0; i < pathSegments.length; i++){
    if(elementSegments[i].contains(r':') && pathSegments[i].isNotEmpty){
      pathParameters["param-${elementSegments[i].replaceFirst(':', '')}"] = pathSegments[i];
    }
  }
  return pathParameters.isEmpty ? {} : {
    element: true, 
    ...pathParameters
  };
}

Module getModule(SerinusModule module){
  final moduleRef = reflect(module);
  int index = moduleRef.type.metadata.indexWhere((element) => element.reflectee is Module);
  if(index == -1){
    throw StateError("It seems ${moduleRef.type.reflectedType} doesn't have the @Module decorator");
  }
  return moduleRef.type.metadata[index].reflectee;
}

Symbol getMiddlewareConfigurer(SerinusModule module){
  final moduleRef = reflect(module);
  final configure = moduleRef.type.instanceMembers[Symbol("configure")];
  return configure?.simpleName ?? Symbol.empty;
}

Map<String, dynamic> getParametersValues(RouteContext context, Map<String, dynamic> routeParameters){
  Map<String, dynamic> sorted = {};
  context.parameters.forEach((d) { 
    for(InstanceMirror meta in d.metadata){
      String type = meta.reflectee.runtimeType.toString().toLowerCase();
      String name = '';
      if(meta.reflectee is Body || meta.reflectee is Req){
        name = MirrorSystem.getName(d.simpleName);
      }else{
        name = meta.reflectee.name;
      }
      if(meta.reflectee is Param || meta.reflectee is Query){
        if(d.type.reflectedType is! String){
          switch(d.type.reflectedType){
            case int:
              routeParameters['$type-$name'] = int.tryParse(routeParameters['$type-$name'] ?? '');
              break;
            case double:
              routeParameters['$type-$name'] = double.tryParse(routeParameters['$type-$name'] ?? '');
              break;
            default:
              break;
          }
        }
        if(!meta.reflectee.nullable && routeParameters['$type-$name'] == null){
          throw BadRequestException(message: "The $type parameter $name doesn't accept null as value");
        }
      }
      sorted['$type-$name'] = routeParameters['$type-$name'];
    }
  });
  return sorted;
}