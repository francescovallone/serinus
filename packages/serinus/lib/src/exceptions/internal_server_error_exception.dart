import 'dart:io';

import 'serinus_exception.dart';

class InternalServerError extends SerinusException{
  const InternalServerError({String message = "Internal server error!", Uri? uri}) : super(
    message: message, 
    uri: uri, 
    statusCode: HttpStatus.internalServerError
  );
}