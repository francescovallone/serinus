import 'package:serinus/src/exceptions/serinus_exception.dart';

/// The class GoneException is used to throw a gone exception
/// 
/// Example:
/// ``` dart
/// throw GoneException();
/// ```
/// 
/// The [message] parameter is optional and is used to define the message of the exception
/// 
/// The [uri] parameter is optional and is used to define the uri of the exception
/// 
/// The [statusCode] is 410
class GoneException extends SerinusException{
  const GoneException({String message = "Gone!", Uri? uri }) : super(
    message: message, 
    uri: uri, 
    statusCode: 410
  );
}