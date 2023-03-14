// coverage:ignore-file
import 'package:mug/mug.dart';

import 'data.service.dart';

@Controller(path: '/data')
class DataController extends MugController{

  final DataService dataService;

  const DataController(this.dataService);

  @Route("/", method: Method.post)
  Map<String, dynamic> ping(
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