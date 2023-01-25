import 'mug_exception.dart';

class UnauthorizedException extends MugException{
  const UnauthorizedException({String message = "Not authorized!", Uri? uri}) : super(message: message, uri: uri, statusCode: 401);
}