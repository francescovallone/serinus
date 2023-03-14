import 'dart:io';

import 'mug_exception.dart';

class BadRequestException extends MugException{
  const BadRequestException({String message = "Bad Request!", Uri? uri }) : super(
    message: message, 
    uri: uri, 
    statusCode: HttpStatus.badRequest
  );
}