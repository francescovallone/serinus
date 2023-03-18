import 'dart:io';

import 'mug_exception.dart';

class InternalServerError extends MugException{
  const InternalServerError({String message = "Internal server error!", Uri? uri}) : super(
    message: message, 
    uri: uri, 
    statusCode: HttpStatus.internalServerError
  );
}