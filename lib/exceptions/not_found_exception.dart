import 'mug_exception.dart';

class NotFoundException extends MugException{
  const NotFoundException({String message = "Not Found!", Uri? uri}) : super(message: message, uri: uri, statusCode: 404);
}