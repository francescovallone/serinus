import 'dart:mirrors';

class Activator{

  static createInstance(Type type, dynamic data){
    var typeMirror = reflectType(type);
    if (typeMirror is ClassMirror) {
      try{
        return typeMirror.newInstance(Symbol('fromJson'), [data]).reflectee;
      }catch(_){}
      try{
        return typeMirror.newInstance(Symbol(''), []).reflectee;
      }catch(_){}
      return typeMirror.reflectedType;
    }else {
      try{
        return Map.of(data);
      }catch(_){}
      try{
        return List.of(data.map((e) => Map.of(e)));
      }catch(_){}
      throw ArgumentError("Cannot create the instance of the type '$type'.");
    }
  }

}