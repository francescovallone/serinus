import 'dart:io';

import 'mug_exception.dart';

class ForbiddenException extends MugException{
  const ForbiddenException({String message = "Forbidden!", Uri? uri}) : super(
    message: message, 
    uri: uri, 
    statusCode: HttpStatus.forbidden
  );
}