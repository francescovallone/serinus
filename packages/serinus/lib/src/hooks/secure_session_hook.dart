import 'dart:convert';
import 'dart:io';

import 'package:secure_session/secure_session.dart';

import '../contexts/contexts.dart';
import '../core/hook.dart';
import '../mixins/mixins.dart';
import '../utils/wrapped_response.dart';

/// The [SecureSessionHook] class is used to create a hook that can be used to secure the session of the request.
class SecureSessionHook extends Hook with OnRequest, OnResponse {
  @override
  SecureSession get service => _secureSession;

  late SecureSession _secureSession;

  /// The [SecureSessionHook] constructor is used to create a new instance of the [SecureSessionHook] class.
  SecureSessionHook({required List<SessionOptions> options}) {
    _secureSession = SecureSession(options: options);
  }

  @override
  Future<void> onRequest(ExecutionContext context) async {
    _secureSession.clear();
    _secureSession.init(context.request.cookies);
  }

  @override
  Future<void> onResponse(
    ExecutionContext context,
    WrappedResponse data,
  ) async {
    for (final option in _secureSession.options) {
      final name = option.cookieName ?? option.defaultSessionName;
      final session = _secureSession.get(name);
      if (session != null) {
        context.response.cookies.add(
          Cookie(name, base64.encode((session.value as String).codeUnits))
            ..maxAge = session.ttl ~/ 1000
            ..expires = DateTime.now().add(Duration(milliseconds: session.ttl))
            ..httpOnly = option.cookieOptions.httpOnly
            ..secure = option.cookieOptions.secure
            ..sameSite = option.cookieOptions.sameSite
            ..domain = option.cookieOptions.domain
            ..path = option.cookieOptions.path,
        );
        continue;
      }
      context.response.cookies.add(
        Cookie(name, '')
          ..maxAge = 0
          ..expires = DateTime.now(),
      );
    }
  }
}
