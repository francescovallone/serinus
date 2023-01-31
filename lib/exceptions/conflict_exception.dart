import 'dart:io';

import 'mug_exception.dart';

class ConflictException extends MugException{
  const ConflictException({String message = "Conflict!", Uri? uri }) : super(
    message: message, 
    uri: uri, 
    statusCode: HttpStatus.conflict
  );
}