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
class BadGatewayException extends SerinusException {
  /// The [BadGatewayException] constructor is used to throw a bad gateway exception
  BadGatewayException({super.message = 'Bad Gateway!', super.uri})
      : super(statusCode: 502);
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
class BadRequestException extends SerinusException {
  /// The [BadRequestException] constructor is used to throw a bad request exception
  BadRequestException({super.message = 'Bad Request!', super.uri})
      : super(statusCode: 400);
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
class ConflictException extends SerinusException {
  /// The [ConflictException] constructor is used to throw a conflict exception
  ConflictException({super.message = 'Conflict!', super.uri})
      : super(statusCode: 409);
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
class ForbiddenException extends SerinusException {
  /// The [ForbiddenException] constructor is used to throw a forbidden exception
  ForbiddenException({super.message = 'Forbidden!', super.uri})
      : super(statusCode: 403);
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
class GatewayTimeoutException extends SerinusException {
  /// The [GatewayTimeoutException] constructor is used to throw a gateway timeout exception
  GatewayTimeoutException({super.message = 'Gateway Timeout!', super.uri})
      : super(statusCode: 504);
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
class GoneException extends SerinusException {
  /// The [GoneException] constructor is used to throw a gone exception
  GoneException({super.message = 'Gone!', super.uri})
      : super(statusCode: 410);
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
class HttpVersionNotSupportedException extends SerinusException {
  /// The [HttpVersionNotSupportedException] constructor is used to throw an http version not supported exception
  HttpVersionNotSupportedException(
      {super.message = 'HTTP Version Not Supported!', super.uri})
      : super(statusCode: 505);
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
class InternalServerErrorException extends SerinusException {
  /// The [InternalServerErrorException] constructor is used to throw a internal server error exception
  InternalServerErrorException(
      {super.message = 'Internal server error!', super.uri})
      : super(statusCode: 500);
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
class MethodNotAllowedException extends SerinusException {
  /// The [MethodNotAllowedException] constructor is used to throw a method not allowed exception
  MethodNotAllowedException(
      {super.message = 'Method not allowed!', super.uri})
      : super(statusCode: 405);
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
class NotAcceptableException extends SerinusException {
  /// The [NotAcceptableException] constructor is used to throw a not acceptable exception
  NotAcceptableException({super.message = 'Not acceptable!', super.uri})
      : super(statusCode: 406);
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
class NotFoundException extends SerinusException {
  /// The [NotFoundException] constructor is used to throw a not found exception
  NotFoundException({super.message = 'Not Found!', super.uri})
      : super(statusCode: 404);
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
class NotImplementedException extends SerinusException {
  /// The [NotImplementedException] constructor is used to throw a not implemented exception
  NotImplementedException({super.message = 'Not Implemented!', super.uri})
      : super(statusCode: 501);
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
class PayloadTooLargeException extends SerinusException {
  /// The [PayloadTooLargeException] constructor is used to throw a payload too large exception
  PayloadTooLargeException(
      {super.message = 'Payload too large!', super.uri})
      : super(statusCode: 413);
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
class PreconditionFailedException extends SerinusException {
  /// The [PreconditionFailedException] constructor is used to throw a precondition failed exception
  PreconditionFailedException(
      {super.message = 'Precondition failed!', super.uri})
      : super(statusCode: 412);
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
class RequestTimeoutException extends SerinusException {
  /// The [RequestTimeoutException] constructor is used to throw a request timeout exception
  RequestTimeoutException({super.message = 'Request timeout!', super.uri})
      : super(statusCode: 408);
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
class ServiceUnavailableException extends SerinusException {
  /// The [ServiceUnavailableException] constructor is used to throw a service unavailable exception
  ServiceUnavailableException(
      {super.message = 'Service unavailable!', super.uri})
      : super(statusCode: 503);
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
class UnauthorizedException extends SerinusException {
  /// The [UnauthorizedException] constructor is used to throw a unauthorized exception
  UnauthorizedException({super.message = 'Not authorized!', super.uri})
      : super(statusCode: 401);
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
  /// The [UnprocessableEntityException] constructor is used to throw a unprocessable entity exception
  UnprocessableEntityException(
      {super.message = 'Unprocessable entity!', super.uri})
      : super(statusCode: 422);
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
  /// The [UnsupportedMediaTypeException] constructor is used to throw a unsupported media type exception
  UnsupportedMediaTypeException(
      {super.message = 'Unsupported media type!', super.uri})
      : super(statusCode: 415);
}

/// Exception thrown when rate limit is exceeded.
class TooManyRequestsException extends SerinusException {
  /// Constructor.
  TooManyRequestsException(
      {super.message = 'Too many requests!', super.statusCode = 429});
}
