import 'dart:io';

import 'serinus_exception.dart';

class MethodNotAllowedException extends SerinusException{
  const MethodNotAllowedException({String message = "Method not allowed!", Uri? uri }) : super(
    message: message, 
    uri: uri, 
    statusCode: HttpStatus.methodNotAllowed
  );
}