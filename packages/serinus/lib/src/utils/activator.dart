import 'dart:mirrors';

class Activator{

  static createInstance(Type type, dynamic data){
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