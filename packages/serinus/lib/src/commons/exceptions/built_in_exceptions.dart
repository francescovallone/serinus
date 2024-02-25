import 'exceptions.dart';

/// The class BadGatewayException is used to throw a bad gateway exception
/// 
/// Example:
/// ``` dart
/// throw BadGatewayException();
/// ```
/// 
/// The [message] parameter is optional and is used to define the message of the exception
/// 
/// The [uri] parameter is optional and is used to define the uri of the exception
/// 
/// The [statusCode] is 502
class BadGatewayException extends SerinusException{
  const BadGatewayException({String message = "Bad Gateway!", Uri? uri }) : super(
    message: message, 
    uri: uri, 
    statusCode: 502
  );
}

/// The class BadRequestException is used to throw a bad request exception
/// 
/// Example:
/// ``` dart
/// throw BadRequestException();
/// ```
/// 
/// The [message] parameter is optional and is used to define the message of the exception
/// 
/// The [uri] parameter is optional and is used to define the uri of the exception
/// 
/// The [statusCode] is 400
class BadRequestException extends SerinusException{
  const BadRequestException({String message = "Bad Request!", Uri? uri }) : super(
    message: message, 
    uri: uri, 
    statusCode: 400
  );
}

/// The class ConflictException is used to throw a conflict exception
/// 
/// Example:
/// 
/// ``` dart
/// throw ConflictException();
/// ```
/// 
/// The [message] parameter is optional and is used to define the message of the exception
/// 
/// The [uri] parameter is optional and is used to define the uri of the exception
/// 
/// The [statusCode] is 409
class ConflictException extends SerinusException{
  const ConflictException({String message = "Conflict!", Uri? uri }) : super(
    message: message, 
    uri: uri, 
    statusCode: 409
  );
}

/// The class ForbiddenException is used to throw a forbidden exception
/// 
/// Example:
/// ``` dart
/// throw ForbiddenException();
/// ```
/// 
/// The [message] parameter is optional and is used to define the message of the exception
/// 
/// The [uri] parameter is optional and is used to define the uri of the exception
/// 
/// The [statusCode] is 403
class ForbiddenException extends SerinusException{
  const ForbiddenException({String message = "Forbidden!", Uri? uri}) : super(
    message: message, 
    uri: uri, 
    statusCode: 403
  );
}

/// The class GatewayTimeoutException is used to throw a gone exception
/// 
/// Example:
/// ``` dart
/// throw GatewayTimeoutException();
/// ```
/// 
/// The [message] parameter is optional and is used to define the message of the exception
/// 
/// The [uri] parameter is optional and is used to define the uri of the exception
/// 
/// The [statusCode] is 504
class GatewayTimeoutException extends SerinusException{
  const GatewayTimeoutException({String message = "Gateway Timeout!", Uri? uri }) : super(
    message: message, 
    uri: uri, 
    statusCode: 504
  );
}

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

/// The class HttpVersionNotSupportedException is used to throw an http version notsupported exception
/// 
/// Example:
/// ``` dart
/// throw HttpVersionNotSupportedException();
/// ```
/// 
/// The [message] parameter is optional and is used to define the message of the exception
/// 
/// The [uri] parameter is optional and is used to define the uri of the exception
/// 
/// The [statusCode] is 505
class HttpVersionNotSupportedException extends SerinusException{
  const HttpVersionNotSupportedException({String message = "HTTP Version Not Supported!", Uri? uri }) : super(
    message: message, 
    uri: uri, 
    statusCode: 505
  );
}

/// The class InternalServerErrorException is used to throw a internal server error exception
/// 
/// Example:
/// ``` dart
/// throw InternalServerErrorException();
/// ```
/// 
/// The [message] parameter is optional and is used to define the message of the exception
/// 
/// The [uri] parameter is optional and is used to define the uri of the exception
/// 
/// The [statusCode] is 500
class InternalServerErrorException extends SerinusException{
  const InternalServerErrorException({String message = "Internal server error!", Uri? uri}) : super(
    message: message, 
    uri: uri, 
    statusCode: 500
  );
}

/// The class MethodNotAllowedException is used to throw a method not allowed exception
/// 
/// Example:
/// ``` dart
/// throw MethodNotAllowedException();
/// ```
/// 
/// The [message] parameter is optional and is used to define the message of the exception
/// 
/// The [uri] parameter is optional and is used to define the uri of the exception
/// 
/// The [statusCode] is 405
class MethodNotAllowedException extends SerinusException{
  const MethodNotAllowedException({String message = "Method not allowed!", Uri? uri }) : super(
    message: message, 
    uri: uri, 
    statusCode: 405
  );
}

/// The class NotAcceptableException is used to throw a not acceptable exception
/// 
/// Example:
/// ``` dart
/// throw NotAcceptableException();
/// ```
/// 
/// The [message] parameter is optional and is used to define the message of the exception
/// 
/// The [uri] parameter is optional and is used to define the uri of the exception
/// 
/// The [statusCode] is 406
class NotAcceptableException extends SerinusException{
  const NotAcceptableException({String message = "Not acceptable!", Uri? uri }) : super(
    message: message, 
    uri: uri, 
    statusCode: 406
  );
}

/// The class NotFoundException is used to throw a not found exception
/// 
/// Example:
/// ``` dart
/// throw NotFoundException();
/// ```
/// 
/// The [message] parameter is optional and is used to define the message of the exception
/// 
/// The [uri] parameter is optional and is used to define the uri of the exception
/// 
/// The [statusCode] is 404
class NotFoundException extends SerinusException{
  const NotFoundException({String message = "Not Found!", Uri? uri}) : super(
    message: message, 
    uri: uri, 
    statusCode: 404
  );
}

/// The class NotImplementedException is used to throw a not implemented exception
/// 
/// Example:
/// ``` dart
/// throw NotImplementedException();
/// ```
/// 
/// The [message] parameter is optional and is used to define the message of the exception
/// 
/// The [uri] parameter is optional and is used to define the uri of the exception
/// 
/// The [statusCode] is 501
class NotImplementedException extends SerinusException{
  const NotImplementedException({String message = "Not Implemented!", Uri? uri}) : super(
    message: message, 
    uri: uri, 
    statusCode: 501
  );
}

/// The class PayloadTooLargeException is used to throw a payload too large exception
/// 
/// Example:
/// ``` dart
/// throw PayloadTooLargeException();
/// ```
/// 
/// The [message] parameter is optional and is used to define the message of the exception
/// 
/// The [uri] parameter is optional and is used to define the uri of the exception
/// 
/// The [statusCode] is 413
class PayloadTooLargeException extends SerinusException{
  const PayloadTooLargeException({String message = "Payload too large!", Uri? uri }) : super(
    message: message, 
    uri: uri, 
    statusCode: 413
  );
}

/// The class PreconditionFailedException is used to throw a precondition failed exception
/// 
/// Example:
/// ``` dart
/// throw PreconditionFailedException();
/// ```
/// 
/// The [message] parameter is optional and is used to define the message of the exception
/// 
/// The [uri] parameter is optional and is used to define the uri of the exception
/// 
/// The [statusCode] is 412
class PreconditionFailedException extends SerinusException{
  const PreconditionFailedException({String message = "Precondition failed!", Uri? uri }) : super(
    message: message, 
    uri: uri, 
    statusCode: 412
  );
}

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
class RequestTimeoutException extends SerinusException{
  const RequestTimeoutException({String message = "Request timeout!", Uri? uri }) : super(
    message: message, 
    uri: uri, 
    statusCode: 408
  );
}

/// The class ServiceUnavailableException is used to throw a service unavailable exception
/// 
/// Example:
/// ``` dart
/// throw ServiceUnavailableException();
/// ```
/// 
/// The [message] parameter is optional and is used to define the message of the exception
/// 
/// The [uri] parameter is optional and is used to define the uri of the exception
/// 
/// The [statusCode] is 503
class ServiceUnavailableException extends SerinusException{
  const ServiceUnavailableException({String message = "Service unavailable!", Uri? uri }) : super(
    message: message, 
    uri: uri, 
    statusCode: 503
  );
}

/// The class UnauthorizedException is used to throw a unauthorized exception
/// 
/// Example:
/// ``` dart
/// throw UnauthorizedException();
/// ```
/// 
/// The [message] parameter is optional and is used to define the message of the exception
/// 
/// The [uri] parameter is optional and is used to define the uri of the exception
/// 
/// The [statusCode] is 401
class UnauthorizedException extends SerinusException{
  const UnauthorizedException({String message = "Not authorized!", Uri? uri}) : super(
    message: message, 
    uri: uri, 
    statusCode: 401
  );
}

/// The class UnprocessableEntityException is used to throw a unsupported media type exception
/// 
/// Example:
/// ``` dart
/// throw UnprocessableEntityException();
/// ```
/// 
/// The [message] parameter is optional and is used to define the message of the exception
/// 
/// The [uri] parameter is optional and is used to define the uri of the exception
/// 
/// The [statusCode] is 422
class UnprocessableEntityException extends SerinusException {
  const UnprocessableEntityException({String message = "Unprocessable entity!", Uri? uri }) : super(
    message: message, 
    uri: uri, 
    statusCode: 422
  );
}

/// The class UnsupportedMediaTypeException is used to throw a unsupported media type exception
/// 
/// Example:
/// ``` dart
/// throw UnsupportedMediaTypeException();
/// ```
/// 
/// The [message] parameter is optional and is used to define the message of the exception
/// 
/// The [uri] parameter is optional and is used to define the uri of the exception
/// 
/// The [statusCode] is 415
class UnsupportedMediaTypeException extends SerinusException {
  const UnsupportedMediaTypeException({String message = "Unsupported media type!", Uri? uri }) : super(
    message: message, 
    uri: uri, 
    statusCode: 415
  );
}