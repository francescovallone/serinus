import 'dart:io';

import 'serinus_exception.dart';

class UnauthorizedException extends SerinusException{
  const UnauthorizedException({String message = "Not authorized!", Uri? uri}) : super(
    message: message, 
    uri: uri, 
    statusCode: HttpStatus.unauthorized
  );
}