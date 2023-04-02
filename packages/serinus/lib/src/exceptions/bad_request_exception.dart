import 'dart:io';

import 'serinus_exception.dart';

class BadRequestException extends SerinusException{
  const BadRequestException({String message = "Bad Request!", Uri? uri }) : super(
    message: message, 
    uri: uri, 
    statusCode: HttpStatus.badRequest
  );
}