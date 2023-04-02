import 'dart:io';

import 'package:serinus/serinus.dart';

class NotFoundException extends SerinusException{
  const NotFoundException({String message = "Not Found!", Uri? uri}) : super(
    message: message, 
    uri: uri, 
    statusCode: HttpStatus.notFound
  );
}