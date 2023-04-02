import 'dart:io';

import 'serinus_exception.dart';

class ForbiddenException extends SerinusException{
  const ForbiddenException({String message = "Forbidden!", Uri? uri}) : super(
    message: message, 
    uri: uri, 
    statusCode: HttpStatus.forbidden
  );
}