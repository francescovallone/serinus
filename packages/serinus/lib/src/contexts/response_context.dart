import 'dart:io';

import '../http/headers.dart';
import 'base_context.dart';

/// The [ResponseContext] class is an utility class that provides a context for the response.
/// It contains properties and methods to manage the response, such as status code, headers, content type, cookies, and more.
class ResponseContext extends BaseContext {
  /// The [ResponseContext] constructor is used to create a new instance of the [ResponseContext] class.
  ResponseContext(super.providers, super.hooksServices);

  bool _closed = false;

  /// The [closed] property indicates if the response context has been closed.
  /// If it is true, it means that the response context has been closed and cannot be modified.
  bool get closed => _closed;

  int _statusCode = HttpStatus.ok;

  /// Allow to read the current status code of the response.
  /// By default it is set to [HttpStatus.ok] for all methods except [HttpMethod.post] which is set to [HttpStatus.created].
  int get statusCode => _statusCode;

  /// Allow to set the status code of the response.
  /// It must be between 100 and 999.
  /// If the status code is not in this range, it will throw an [ArgumentError].
  set statusCode(int value) {
    if (_closed) {
      throw StateError(
        'Response context has been closed and cannot be modified.',
      );
    }
    if (value < 100 || value > 999) {
      throw ArgumentError(
        'The status code must be between 100 and 999. $value is not a valid status code.',
      );
    }
    _statusCode = value;
  }

  final Map<String, String> _headers = {};

  /// The [headers] property contains the headers of the response.
  /// It is a [SerinusHeaders] object that allows to add, remove and modify headers.
  /// The headers are lazy loaded, meaning they will only be fetched when requested.
  Map<String, String> get headers => _headers;

  ContentType? _contentType;
  String? _contentTypeString;

  /// The [contentType] property contains the content type of the response.
  ContentType? get contentType => _contentType;

  /// Cached string representation of the content type to avoid repeated allocations.
  String? get contentTypeString => _contentTypeString;

  /// Allow to change the content type of the response.
  /// If the content type is set to null, it will remove the content type header from the response.
  set contentType(ContentType? value) {
    if (_closed) {
      throw StateError(
        'Response context has been closed and cannot be modified.',
      );
    }
    _contentType = value;
    if (value != null) {
      _contentTypeString = value.toString();
      headers[HttpHeaders.contentTypeHeader] = _contentTypeString!;
    } else {
      _contentTypeString = null;
      headers.remove(HttpHeaders.contentTypeHeader);
    }
  }

  /// The [addHeader] method is used to add a header to the response.
  /// If the response context is closed, it will throw a [StateError].
  void addHeader(String name, String value) {
    if (_closed) {
      throw StateError(
        'Response context has been closed and cannot be modified.',
      );
    }
    _headers[name] = value;
  }

  /// The [addHeaders] method is used to add multiple headers to the response.
  /// If the response context is closed, it will throw a [StateError].
  void addHeaders(Map<String, String> headers) {
    if (_closed) {
      throw StateError(
        'Response context has been closed and cannot be modified.',
      );
    }
    _headers.addAll(headers);
  }

  int? _contentLength;

  /// Set the content length of the response.
  /// If the response context is closed, it will throw a [StateError].
  /// If the content length is set to null, it will use the calculated length of the body.
  /// This is useful when the content length is not known in advance.
  set contentLength(int? contentLength) {
    if (_closed) {
      throw StateError(
        'Response properties have been closed and cannot be modified.',
      );
    }
    _contentLength = contentLength;
    if (contentLength != null) {
      _headers[HttpHeaders.contentLengthHeader] = contentLength.toString();
    } else {
      _headers.remove(HttpHeaders.contentLengthHeader);
    }
  }

  /// Allow to read the content length of the response.
  /// By default it is set to null, meaning that the content length is not known in advance.
  int? get contentLength => _contentLength;

  final List<Cookie> _cookies = [];

  /// Allow to read the current cookies of the response.
  /// It is a list of [Cookie] objects that can be used to set cookies in the response.
  List<Cookie> get cookies => _cookies;

  /// The [addCookie] method is used to add a cookie to the response.
  void addCookie(Cookie cookie) {
    if (_closed) {
      throw StateError(
        'Response properties have been closed and cannot be modified.',
      );
    }
    _cookies.add(cookie);
  }

  /// The [addCookies] method is used to add multiple cookies to the response.
  void addCookies(List<Cookie> cookies) {
    if (_closed) {
      throw StateError(
        'Response properties have been closed and cannot be modified.',
      );
    }
    _cookies.addAll(cookies);
  }

  Object? _body;

  /// The [body] property contains the body of the response.
  /// It can be of any type, depending on the content type of the response.
  Object? get body => _body;

  set body(Object? value) {
    if (_closed) {
      throw StateError(
        'Response context has been closed and cannot be modified.',
      );
    }
    _body = value;
    close();
  }

  /// The [close] method is used to close the response context.
  /// This method should be called when the response will be sent back to the client forcefully without completing the request.
  /// It prevents further modifications to the response context.
  /// This method is idempotent, meaning it can be called multiple times without changing the result.
  void close() {
    _closed = true;
  }
}

/// The [ResponseProperties] class is used to create the response properties.
///
/// It contains the status code, headers, and redirect properties.
@Deprecated(
  'The ResponseProperties will be removed in future versions. Use ResponseContext instead.',
)
final class ResponseProperties {
  /// The [statusCode] property contains the status code of the response.
  int _statusCode = HttpStatus.ok;

  /// The [statusCode] getter is used to get the status code of the response.
  int get statusCode => _statusCode;

  /// The [statusCode] setter is used to set the status code of the response.
  set statusCode(int value) {
    if (value < 100 || value > 999) {
      throw ArgumentError(
        'The status code must be between 100 and 999. $value is not a valid status code.',
      );
    }
    _statusCode = value;
  }

  /// The [contentType] property contains the content type of the response.
  ContentType? _contentType;

  /// The [contentLength] property contains the content length of the response.
  int? _contentLength;

  /// The [headers] property contains the headers of the response.
  final Map<String, String> _headers = {};

  /// The [headers] getter is used to get the headers of the response.
  Map<String, String> get headers => _headers;

  /// The [cookies] property contains the cookies that should be sent back to the client.
  final List<Cookie> _cookies = [];

  /// The [cookies] getter is used to get the cookies of the response.
  List<Cookie> get cookies => _cookies;

  /// The [addCookie] method is used to add a cookie to the response.
  void addCookie(Cookie cookie) {
    if (_closed) {
      throw StateError(
        'Response properties have been closed and cannot be modified.',
      );
    }
    _cookies.add(cookie);
  }

  /// The [addCookies] method is used to add multiple cookies to the response.
  void addCookies(List<Cookie> cookies) {
    if (_closed) {
      throw StateError(
        'Response properties have been closed and cannot be modified.',
      );
    }
    _cookies.addAll(cookies);
  }

  /// The [addHeader] method is used to add a header to the response.
  void addHeader(String name, String value) {
    if (_closed) {
      throw StateError(
        'Response properties have been closed and cannot be modified.',
      );
    }
    _headers[name] = value;
  }

  /// The [addHeaders] method is used to add multiple headers to the response.
  void addHeaders(Map<String, String> headers) {
    if (_closed) {
      throw StateError(
        'Response properties have been closed and cannot be modified.',
      );
    }
    _headers.addAll(headers);
  }

  set contentType(ContentType? contentType) {
    if (_closed) {
      throw StateError(
        'Response properties have been closed and cannot be modified.',
      );
    }
    _contentType = contentType;
    if (contentType != null) {
      _headers[HttpHeaders.contentTypeHeader] = contentType.toString();
    } else {
      _headers.remove(HttpHeaders.contentTypeHeader);
    }
  }

  /// The [contentType] getter is used to get the content type of the response.
  ContentType? get contentType => _contentType;

  set contentLength(int? contentLength) {
    if (_closed) {
      throw StateError(
        'Response properties have been closed and cannot be modified.',
      );
    }
    _contentLength = contentLength;
    if (contentLength != null) {
      _headers[HttpHeaders.contentLengthHeader] = contentLength.toString();
    } else {
      _headers.remove(HttpHeaders.contentLengthHeader);
    }
  }

  /// The [contentLength] getter is used to get the content length of the response.
  int? get contentLength => _contentLength;

  /// The [ResponseProperties] constructor.
  ResponseProperties({
    ContentType? contentType,
    int? contentLength,
    List<Cookie> cookies = const [],
  }) {
    _contentType = contentType;
    _contentLength = contentLength;
    _headers.addAll({
      HttpHeaders.contentTypeHeader:
          contentType?.toString() ?? ContentType.text.toString(),
      HttpHeaders.contentLengthHeader: contentLength?.toString() ?? '0',
    });
    _cookies.addAll(cookies);
  }

  /// The [change] method is used to force change the response properties.
  ResponseProperties change({
    ContentType? contentType,
    int? contentLength,
    List<Cookie>? cookies,
  }) {
    if (_closed) {
      throw StateError(
        'Response properties have been closed and cannot be modified.',
      );
    }
    return ResponseProperties(
      contentType: contentType ?? this.contentType,
      contentLength: contentLength ?? this.contentLength,
      cookies: cookies ?? this.cookies,
    );
  }

  bool _closed = false;

  /// The [closed] property indicates if the response properties have been closed.
  bool get closed => _closed;

  /// The [close] method is used to close the response properties.
  /// This method should be called when the response will be sent back to the client forcefully without completing the request.
  /// It prevents further modifications to the response properties.
  void close() {
    if (!_closed) {
      _closed = true;
    }
  }
}
