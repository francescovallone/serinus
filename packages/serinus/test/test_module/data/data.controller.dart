// coverage:ignore-file
import 'package:serinus/serinus.dart';

import 'data.service.dart';

@Controller('/data')
class DataController extends SerinusController{

  final DataService dataService;

  const DataController(this.dataService);

  @Post()
  Map<String, dynamic> ping(
    @Req() Request request,
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
    @Param('id') String id,
    @Query('num', nullable: true) int? number1,
    @Query('num2', nullable: true) double? number2,
    @Query('value') int number3
  ){
    return id;
  }

  @Put(path: "/data")
  String putRoute(){
    return "PUT";
  }

  @Delete(path: "/data")
  String deleteRoute(){
    return "DELETE";
  }

  @Head(path: "/data")
  String headRoute(){
    return "HEAD";
  }

  @Options(path: "/data")
  String optionsRoute(){
    return "OPTIONS";
  }

  @Patch(path: "/data")
  String patchRoute(){
    return "PATCH";
  }

}