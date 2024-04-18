import 'dart:convert';
import 'dart:io';

import 'package:serinus/serinus.dart';

class ServeRouteGet extends Route{
  
  const ServeRouteGet({super.path = '/*', super.method = HttpMethod.get});

}

class ServeStaticController extends Controller{

  final List<String> excludePaths;

  ServeStaticController({required super.path, this.excludePaths = const [],}){
    on(ServeRouteGet(), (context) async {
      final path = context.request.path;
      Directory current = Directory.current;
      print('Current path: ${Uri(path: '${current.path}/$path').path.replaceAll('//', '/')}');
      final file = File('${current.path}/$path');
      // if(excludePaths.isNotEmpty){
      //   for(var excludePath in excludePaths){
      //     if(path.startsWith(excludePath)){
      //       throw NotFoundException(message: "The file $path does not exist");
      //     }
      //   }
      // }
      if(!file.existsSync()){
        throw NotFoundException(message: "The file $path does not exist");
      }
      // final byteSink = ByteAccumulatorSink();
      // await file.openRead().listen(byteSink.add).asFuture();
      return Response.text(data: Utf8Decoder().convert([]));
    });
  }

}