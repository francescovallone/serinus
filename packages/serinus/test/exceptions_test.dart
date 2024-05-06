import 'package:serinus/serinus.dart';
import 'package:test/test.dart';

void main() {
  test('should instantiate a BadRequestException with custom message', () {
      BadRequestException exception =
          BadRequestException(message: 'Custom message!');
      expect(exception.statusCode, 400);
      expect(exception.message, 'Custom message!');
    });

    test('should instantiate a ConflictException with custom message', () {
      ConflictException exception =
          ConflictException(message: 'Custom message!');
      expect(exception.statusCode, 409);
      expect(exception.message, 'Custom message!');
    });

    test('should instantiate a ForbiddenException with custom message', () {
      ForbiddenException exception =
          ForbiddenException(message: 'Custom message!');
      expect(exception.statusCode, 403);
      expect(exception.message, 'Custom message!');
    });

    test('should instantiate a GoneException with custom message', () {
      GoneException exception = GoneException(message: 'Custom message!');
      expect(exception.statusCode, 410);
      expect(exception.message, 'Custom message!');
    });

    test('should instantiate a InternalServerError with custom message', () {
      final exception =
          InternalServerErrorException(message: 'Custom message!');
      expect(exception.statusCode, 500);
      expect(exception.message, 'Custom message!');
    });

    test('should instantiate a MethodNotAllowedException with custom message',
        () {
      MethodNotAllowedException exception =
          MethodNotAllowedException(message: 'Custom message!');
      expect(exception.statusCode, 405);
      expect(exception.message, 'Custom message!');
    });

    test('should instantiate a NotAcceptableException with custom message', () {
      NotAcceptableException exception =
          NotAcceptableException(message: 'Custom message!');
      expect(exception.statusCode, 406);
      expect(exception.message, 'Custom message!');
    });

    test('should instantiate a NotFoundException with custom message', () {
      NotFoundException exception =
          NotFoundException(message: 'Custom message!');
      expect(exception.statusCode, 404);
      expect(exception.message, 'Custom message!');
    });

    test('should instantiate a RequestTimeoutException with custom message',
        () {
      RequestTimeoutException exception =
          RequestTimeoutException(message: 'Custom message!');
      expect(exception.statusCode, 408);
      expect(exception.message, 'Custom message!');
    });

    test('should instantiate a UnauthorizedException with custom message', () {
      UnauthorizedException exception =
          UnauthorizedException(message: 'Custom message!');
      expect(exception.statusCode, 401);
      expect(exception.message, 'Custom message!');
    });

    test(
        'should instantiate a UnprocessableEntityException with custom message',
        () {
      UnprocessableEntityException exception =
          UnprocessableEntityException(message: 'Custom message!');
      expect(exception.statusCode, 422);
      expect(exception.message, 'Custom message!');
    });

    test(
        'should instantiate a UnsupportedMediaTypeException with custom message',
        () {
      UnsupportedMediaTypeException exception =
          UnsupportedMediaTypeException(message: 'Custom message!');
      expect(exception.statusCode, 415);
      expect(exception.message, 'Custom message!');
    });

    test('should instantiate a SerinusException with custom message', () {
      SerinusException exception =
          SerinusException(message: 'Custom message!', statusCode: 500);
      expect(exception.statusCode, 500);
      expect(exception.message, 'Custom message!');
      expect(exception.toString(),
          '{"message":"Custom message!","statusCode":500,"uri":"No Uri"}');
    });

    test('should instantiate a BadGatewayException with custom message', () {
      BadGatewayException exception =
          BadGatewayException(message: 'Custom message!');
      expect(exception.statusCode, 502);
      expect(exception.message, 'Custom message!');
    });

    test('should instantiate a GatewayTimeoutException with custom message',
        () {
      GatewayTimeoutException exception =
          GatewayTimeoutException(message: 'Custom message!');
      expect(exception.statusCode, 504);
      expect(exception.message, 'Custom message!');
    });

    test('should instantiate a ServiceUnavailableException with custom message',
        () {
      ServiceUnavailableException exception =
          ServiceUnavailableException(message: 'Custom message!');
      expect(exception.statusCode, 503);
      expect(exception.message, 'Custom message!');
    });

    test(
        'should instantiate a HttpVersionNotSupportedException with custom message',
        () {
      HttpVersionNotSupportedException exception =
          HttpVersionNotSupportedException(message: 'Custom message!');
      expect(exception.statusCode, 505);
      expect(exception.message, 'Custom message!');
    });

    test('should instantiate a NotImplementedException with custom message',
        () {
      NotImplementedException exception =
          NotImplementedException(message: 'Custom message!');
      expect(exception.statusCode, 501);
      expect(exception.message, 'Custom message!');
    });

    test('should instantiate a PayloadTooLargeException with custom message',
        () {
      PayloadTooLargeException exception =
          PayloadTooLargeException(message: 'Custom message!');
      expect(exception.statusCode, 413);
      expect(exception.message, 'Custom message!');
    });

    test('should instantiate a PreconditionFailedException with custom message',
        () {
      PreconditionFailedException exception =
          PreconditionFailedException(message: 'Custom message!');
      expect(exception.statusCode, 412);
      expect(exception.message, 'Custom message!');
    });
}
