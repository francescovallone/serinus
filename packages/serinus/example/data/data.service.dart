import 'package:serinus/serinus.dart';

import '../app_service_copy.dart';

class DataService extends SerinusProvider{

  DataService(AppServiceCopy appServiceCopy);

  String printHello(String value){
    return "HELLO $value";
  }

}