import 'dart:io';

import 'mug_exception.dart';

class MethodNotAllowedException extends MugException{
  const MethodNotAllowedException({String message = "Method not allowed!", Uri? uri }) : super(
    message: message, 
    uri: uri, 
    statusCode: HttpStatus.methodNotAllowed
  );
}