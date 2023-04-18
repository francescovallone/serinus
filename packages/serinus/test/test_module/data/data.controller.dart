// coverage:ignore-file
import 'package:serinus/serinus.dart';

import 'data.service.dart';

@Controller('/data')
class DataController extends SerinusController{

  final DataService dataService;

  const DataController(this.dataService);

  @Route("/", method: Method.post)
  Map<String, dynamic> ping(
    @RequestInfo() Request request,
    @Body() body,
  ){
    return {
      "key": "value"
    };
  }

  @Route("/data", method: Method.get)
  String queryRoute(
    @Query('id') String id
  ){
    return id;
  }

  @Route("/data", method: Method.get)
  Map<String, dynamic> data(){
    return {
      "hello": "HELLO"
    };
  }

  @Route("/data/:id", method: Method.get)
  String paramRoute(
    @Param('id') String id
  ){
    return id;
  }

}