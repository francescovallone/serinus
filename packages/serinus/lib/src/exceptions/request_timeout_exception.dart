import 'serinus_exception.dart';

class RequestTimeoutException extends SerinusException{
  const RequestTimeoutException({String message = "Request timeout!", Uri? uri }) : super(
    message: message, 
    uri: uri, 
    statusCode: 408
  );
}