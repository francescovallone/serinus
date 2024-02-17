import 'dart:mirrors';

import 'package:serinus/serinus.dart';
import 'package:serinus/src/commons/extensions/string_extensions.dart';

extension JsonParsing on dynamic {

  String toJsonString() {
    final stringifiedObject = this.toString();
    if (stringifiedObject.isJson()) {
      return stringifiedObject;
    }
    try {
      return jsonEncode(this);
    } catch (e) {
      throw StateError("Error while parsing json");
    }
  }

  Map<String, dynamic> convertMap() {
    Map<String, dynamic> convertedMap = {};
    for (var key in this.keys) {
      if (this[key] is Map) {
        convertedMap[key.toString()] = this[key].convertMap();
      }else if(this[key] is UploadedFile){
        convertedMap[key.toString()] = this[key].toString();
      }else if(this[key] is FormData){
        convertedMap[key.toString()] = this[key].convertMap();
      }else{
        convertedMap[key.toString()] = this[key];
      }
    }
    return Map<String, dynamic>.from(convertedMap);
  }

}

extension InstantiableObject on dynamic {
  Object createInstance(Type type, dynamic data){
    ClassMirror typeMirror = reflectClass(type);
    try{
      if(typeMirror.declarations.containsKey(Symbol('$type.fromJson'))){
        return typeMirror.newInstance(Symbol('fromJson'), [data]).reflectee;
      }else{
        return typeMirror.newInstance(Symbol(''), []).reflectee;
      }
    }catch(e){
      throw ArgumentError("Cannot create the instance of the type '$type'.");
    }
  }
}
