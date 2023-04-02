import 'dart:io';

import 'serinus_exception.dart';

class ConflictException extends SerinusException{
  const ConflictException({String message = "Conflict!", Uri? uri }) : super(
    message: message, 
    uri: uri, 
    statusCode: HttpStatus.conflict
  );
}