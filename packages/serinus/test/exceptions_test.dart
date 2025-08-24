import 'package:serinus/serinus.dart';
import 'package:test/test.dart';

void main() {
  test('should instantiate a BadRequestException with custom message', () {
    BadRequestException exception = BadRequestException('Custom message!');
    expect(exception.statusCode, 400);
    expect(exception.message, 'Custom message!');
  });

  test('should instantiate a ConflictException with custom message', () {
    ConflictException exception = ConflictException('Custom message!');
    expect(exception.statusCode, 409);
    expect(exception.message, 'Custom message!');
  });

  test('should instantiate a ForbiddenException with custom message', () {
    ForbiddenException exception = ForbiddenException('Custom message!');
    expect(exception.statusCode, 403);
    expect(exception.message, 'Custom message!');
  });

  test('should instantiate a GoneException with custom message', () {
    GoneException exception = GoneException('Custom message!');
    expect(exception.statusCode, 410);
    expect(exception.message, 'Custom message!');
  });

  test('should instantiate a InternalServerError with custom message', () {
    final exception = InternalServerErrorException('Custom message!');
    expect(exception.statusCode, 500);
    expect(exception.message, 'Custom message!');
  });

  test(
    'should instantiate a MethodNotAllowedException with custom message',
    () {
      MethodNotAllowedException exception = MethodNotAllowedException(
        'Custom message!',
      );
      expect(exception.statusCode, 405);
      expect(exception.message, 'Custom message!');
    },
  );

  test('should instantiate a NotAcceptableException with custom message', () {
    NotAcceptableException exception = NotAcceptableException(
      'Custom message!',
    );
    expect(exception.statusCode, 406);
    expect(exception.message, 'Custom message!');
  });

  test('should instantiate a NotFoundException with custom message', () {
    NotFoundException exception = NotFoundException('Custom message!');
    expect(exception.statusCode, 404);
    expect(exception.message, 'Custom message!');
  });

  test('should instantiate a RequestTimeoutException with custom message', () {
    RequestTimeoutException exception = RequestTimeoutException(
      'Custom message!',
    );
    expect(exception.statusCode, 408);
    expect(exception.message, 'Custom message!');
  });

  test('should instantiate a UnauthorizedException with custom message', () {
    UnauthorizedException exception = UnauthorizedException('Custom message!');
    expect(exception.statusCode, 401);
    expect(exception.message, 'Custom message!');
  });

  test(
    'should instantiate a UnprocessableEntityException with custom message',
    () {
      UnprocessableEntityException exception = UnprocessableEntityException(
        'Custom message!',
      );
      expect(exception.statusCode, 422);
      expect(exception.message, 'Custom message!');
    },
  );

  test(
    'should instantiate a UnsupportedMediaTypeException with custom message',
    () {
      UnsupportedMediaTypeException exception = UnsupportedMediaTypeException(
        'Custom message!',
      );
      expect(exception.statusCode, 415);
      expect(exception.message, 'Custom message!');
    },
  );

  test('should instantiate a SerinusException with custom message', () {
    SerinusException exception = SerinusException(
      message: 'Custom message!',
      statusCode: 500,
    );
    expect(exception.statusCode, 500);
    expect(exception.message, 'Custom message!');
    expect(exception.toJson(), {
      'message': 'Custom message!',
      'statusCode': 500,
      'uri': 'No Uri',
    });
  });

  test('should instantiate a BadGatewayException with custom message', () {
    BadGatewayException exception = BadGatewayException('Custom message!');
    expect(exception.statusCode, 502);
    expect(exception.message, 'Custom message!');
  });

  test('should instantiate a GatewayTimeoutException with custom message', () {
    GatewayTimeoutException exception = GatewayTimeoutException(
      'Custom message!',
    );
    expect(exception.statusCode, 504);
    expect(exception.message, 'Custom message!');
  });

  test(
    'should instantiate a ServiceUnavailableException with custom message',
    () {
      ServiceUnavailableException exception = ServiceUnavailableException(
        'Custom message!',
      );
      expect(exception.statusCode, 503);
      expect(exception.message, 'Custom message!');
    },
  );

  test(
    'should instantiate a HttpVersionNotSupportedException with custom message',
    () {
      HttpVersionNotSupportedException exception =
          HttpVersionNotSupportedException('Custom message!');
      expect(exception.statusCode, 505);
      expect(exception.message, 'Custom message!');
    },
  );

  test('should instantiate a NotImplementedException with custom message', () {
    NotImplementedException exception = NotImplementedException(
      'Custom message!',
    );
    expect(exception.statusCode, 501);
    expect(exception.message, 'Custom message!');
  });

  test('should instantiate a PayloadTooLargeException with custom message', () {
    PayloadTooLargeException exception = PayloadTooLargeException(
      'Custom message!',
    );
    expect(exception.statusCode, 413);
    expect(exception.message, 'Custom message!');
  });

  test(
    'should instantiate a PreconditionFailedException with custom message',
    () {
      PreconditionFailedException exception = PreconditionFailedException(
        'Custom message!',
      );
      expect(exception.statusCode, 412);
      expect(exception.message, 'Custom message!');
    },
  );
  test(
    'should instantiate a TooManyRequests with default message and status code',
    () {
      TooManyRequestsException exception = TooManyRequestsException();
      expect(exception.statusCode, 429);
      expect(exception.message, 'Too Many Requests!');
    },
  );
}
