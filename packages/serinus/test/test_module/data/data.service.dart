// coverage:ignore-file
import 'package:serinus/serinus.dart';

class DataService extends SerinusProvider with ApplicationInit{

  String printHello(String value){
    return "HELLO $value";
  }
  
  @override
  void onInit() => print("DataService is initialized!");

}