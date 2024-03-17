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

}