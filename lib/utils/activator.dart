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
      print(typeMirror.hasReflectedType);
      return typeMirror.reflectedType;
    } else {
      throw ArgumentError("Cannot create the instance of the type '$type'.");
    }
  }

}