import 'dart:io';

import 'package:uuid/uuid.dart';

import '../../serinus.dart';

/// A hook that provides CSRF protection for HTTP requests.
class CsrfHook extends Hook with OnRequest, OnResponse {
  /// Methods to ignore (do not validate CSRF token for these).
  final List<String> ignoreMethods;

  /// The name of the header to check for the token.
  final String headerName;

  /// The key used to store the token in the session.
  final String sessionKey;

  /// UUID generator for secure tokens.
  final Uuid _uuid = const Uuid();

  /// The name of the cookie to set with the CSRF token.
  final String cookieName;

  /// A callback function that is called when the CSRF token is invalid.
  final SerinusException Function() onTokenInvalid;

  /// Default handler for invalid CSRF tokens.
  static SerinusException _defaultOnTokenInvalid() {
    return ForbiddenException('Invalid CSRF Token');
  }

  /// Creates a new instance of the [CsrfHook] class.
  CsrfHook({
    this.ignoreMethods = const ['GET', 'HEAD', 'OPTIONS'],
    this.headerName = 'x-csrf-token',
    this.sessionKey = 'csrf_token',
    this.cookieName = 'XSRF-TOKEN',
    this.onTokenInvalid = _defaultOnTokenInvalid,
  });

  @override
  Future<void> onRequest(ExecutionContext context) async {
    if (context.argumentsHost is! HttpArgumentsHost) {
      return;
    }
    final requestContext = context.switchToHttp();
    final request = requestContext.request;
    final session = request.session;
    if (session.get(sessionKey) == null) {
      session.put(sessionKey, _uuid.v4());
    }
    final token = session.get(sessionKey);
    request.addData('csrfToken', token);
    if (ignoreMethods.contains(request.method.name.toUpperCase())) {
      return;
    }
    final incomingToken = request.headers[headerName];
    if (incomingToken == null || incomingToken != token) {
      throw onTokenInvalid();
    }
  }

  @override
  Future<void> onResponse(
    ExecutionContext context,
    WrappedResponse response,
  ) async {
    if (context.argumentsHost is! HttpArgumentsHost) {
      return;
    }
    final requestContext = context.switchToHttp();
    final request = requestContext.request;
    final token = request.getData('csrfToken') as String?;
    if (token != null) {
      context.response.cookies.add(
        Cookie(cookieName, token)
          ..httpOnly = false
          ..path = '/'
          ..secure = true
          ..sameSite = SameSite.strict,
      );
    }
  }
}
