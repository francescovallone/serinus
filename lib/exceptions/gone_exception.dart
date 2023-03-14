import 'mug_exception.dart';

class GoneException extends MugException{
  const GoneException({String message = "Gone!", Uri? uri }) : super(
    message: message, 
    uri: uri, 
    statusCode: 410
  );
}