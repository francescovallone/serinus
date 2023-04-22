// coverage:ignore-file
import 'package:serinus/serinus.dart';

import 'data.service.dart';

@Controller('/data')
class DataController extends SerinusController{

  final DataService dataService;

  const DataController(this.dataService);

  @Post()
  Map<String, dynamic> ping(
    @RequestInfo() Request request,
    @Body() body,
  ){
    return {
      "key": "value"
    };
  }

  @Get(path: "/data")
  String queryRoute(
    @Query('id') String id
  ){
    return id;
  }

  @Get(path: "/data")
  Map<String, dynamic> data(){
    return {
      "hello": "HELLO"
    };
  }

  @Get(path: "/data/:id")
  String paramRoute(
    @Param('id') String id
  ){
    return id;
  }

}