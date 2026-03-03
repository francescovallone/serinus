# CSRF Protection

CSRF (Cross-Site Request Forgery) protection is a security feature that prevents unauthorized commands from being executed on behalf of an authenticated user. Serinus provides a built-in CSRF hook to help developers implement this protection in their applications.

The CSRF hook works by generating a unique token for each user session and validating it on each request that modifies data (e.g., POST, PUT, DELETE). This ensures that only requests originating from the same domain are allowed to modify data.

## Usage

To use the CSRF hook, simply add it to your application's hooks list:

```dart
import 'package:serinus/serinus.dart';
import 'package:serinus/hooks/csrf_hook.dart';

void main() {
  final application = await serinus.createApplication(
    entrypoint: AppModule(),
  );
  application.use(CsrfHook());
  await application.serve();
}
```

The hook will automatically generate and validate CSRF tokens for all HTTP requests. It skips validation for safe methods like GET, HEAD, and OPTIONS.

## Configuration

The `CsrfHook` can be configured with the following parameters:

- `ignoreMethods`: A list of HTTP methods for which CSRF validation is skipped (default: `['GET', 'HEAD', 'OPTIONS']`).
- `headerName`: The name of the header to check for the CSRF token (default: `'x-csrf-token'`).
- `sessionKey`: The key used to store the CSRF token in the session (default: `'csrf_token'`).
- `cookieName`: The name of the cookie to set with the CSRF token (default: `'XSRF-TOKEN'`).
- `onTokenInvalid`: A callback function that is called when the CSRF token is invalid. By default, it returns a `ForbiddenException` with the message 'Invalid CSRF Token'.

Example configuration:

```dart
CsrfHook(
  ignoreMethods: ['GET', 'HEAD'],
  headerName: 'X-CSRF-Token',
  sessionKey: 'my_custom_csrf_key',
  cookieName: 'MY_CUSTOM_COOKIE_NAME',
  onTokenInvalid: () {
    // Custom handling for invalid CSRF tokens
    print('CSRF token is invalid');
    return ForbiddenException('Custom CSRF error message');
  },
)
```
