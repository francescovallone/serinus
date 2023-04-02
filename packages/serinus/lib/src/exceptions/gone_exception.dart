import 'serinus_exception.dart';

class GoneException extends SerinusException{
  const GoneException({String message = "Gone!", Uri? uri }) : super(
    message: message, 
    uri: uri, 
    statusCode: 410
  );
}