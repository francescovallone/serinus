import 'dart:convert';
import 'dart:io';

import 'package:secure_session/secure_session.dart';

import '../contexts/contexts.dart';
import '../core/hook.dart';
import '../http/request.dart';
import '../mixins/mixins.dart';

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
  Future<void> onRequest(Request request, ResponseContext properties) async {
    _secureSession.clear();
    _secureSession.init(request.cookies);
  }

  @override
  Future<void> onResponse(
    Request request,
    dynamic data,
    ResponseContext properties,
  ) async {
    for (final option in _secureSession.options) {
      final name = option.cookieName ?? option.defaultSessionName;
      final session = _secureSession.get(name);
      if (session != null) {
        properties.cookies.add(
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
      properties.cookies.add(
        Cookie(name, '')
          ..maxAge = 0
          ..expires = DateTime.now(),
      );
    }
  }
}
