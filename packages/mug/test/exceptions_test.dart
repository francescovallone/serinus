
import 'package:mug/mug.dart';
import 'package:test/test.dart';

void main() {

  test("should instantiate a BadRequestException with custom message", (){
    BadRequestException exception = BadRequestException(
      message: "Custom message!"
    );
    expect(exception.statusCode, 400);
    expect(exception.message, "Custom message!");
  });

  test("should instantiate a ConflictException with custom message", (){
    ConflictException exception = ConflictException(
      message: "Custom message!"
    );
    expect(exception.statusCode, 409);
    expect(exception.message, "Custom message!");
  });

  test("should instantiate a ForbiddenException with custom message", (){
    ForbiddenException exception = ForbiddenException(
      message: "Custom message!"
    );
    expect(exception.statusCode, 403);
    expect(exception.message, "Custom message!");
  });

  test("should instantiate a GoneException with custom message", (){
    GoneException exception = GoneException(
      message: "Custom message!"
    );
    expect(exception.statusCode, 410);
    expect(exception.message, "Custom message!");
  });

  test("should instantiate a InternalServerError with custom message", (){
    InternalServerError exception = InternalServerError(
      message: "Custom message!"
    );
    expect(exception.statusCode, 500);
    expect(exception.message, "Custom message!");
  });

  test("should instantiate a MethodNotAllowedException with custom message", (){
    MethodNotAllowedException exception = MethodNotAllowedException(
      message: "Custom message!"
    );
    expect(exception.statusCode, 405);
    expect(exception.message, "Custom message!");
  });

  test("should instantiate a NotAcceptableException with custom message", (){
    NotAcceptableException exception = NotAcceptableException(
      message: "Custom message!"
    );
    expect(exception.statusCode, 406);
    expect(exception.message, "Custom message!");
  });

  test("should instantiate a NotFoundException with custom message", (){
    NotFoundException exception = NotFoundException(
      message: "Custom message!"
    );
    expect(exception.statusCode, 404);
    expect(exception.message, "Custom message!");
  });

  test("should instantiate a RequestTimeoutException with custom message", (){
    RequestTimeoutException exception = RequestTimeoutException(
      message: "Custom message!"
    );
    expect(exception.statusCode, 408);
    expect(exception.message, "Custom message!");
  });

  test("should instantiate a UnauthorizedException with custom message", (){
    UnauthorizedException exception = UnauthorizedException(
      message: "Custom message!"
    );
    expect(exception.statusCode, 401);
    expect(exception.message, "Custom message!");
  });

}
