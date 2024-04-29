import 'dart:convert';

extension JsonString on String {
  
  bool isJson(){
    try{
      jsonDecode(this);
      return true;
    }catch(e){
      return false;
    }
  }

  dynamic tryParse(){
    try{
      return jsonDecode(this);
    }catch(e){
      return null;
    }
  }

}