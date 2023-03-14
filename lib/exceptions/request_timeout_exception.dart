import 'mug_exception.dart';

class RequestTimeoutException extends MugException{
  const RequestTimeoutException({String message = "Request timeout!", Uri? uri }) : super(
    message: message, 
    uri: uri, 
    statusCode: 408
  );
}