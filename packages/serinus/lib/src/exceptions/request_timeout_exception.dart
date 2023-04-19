import 'serinus_exception.dart';

/// The class RequestTimeoutException is used to throw a request timeout exception
/// 
/// Example:
/// ``` dart
/// throw RequestTimeoutException();
/// ```
/// 
/// The [message] parameter is optional and is used to define the message of the exception
/// 
/// The [uri] parameter is optional and is used to define the uri of the exception
/// 
/// The [statusCode] is 408
/// 
/// See also:
class RequestTimeoutException extends SerinusException{
  const RequestTimeoutException({String message = "Request timeout!", Uri? uri }) : super(
    message: message, 
    uri: uri, 
    statusCode: 408
  );
}