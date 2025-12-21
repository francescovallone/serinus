import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:mime/mime.dart';

import '../containers/models_provider.dart';
import '../core/core.dart';
import '../exceptions/exceptions.dart';
import '../extensions/content_type_extensions.dart';
import '../http/http.dart';
import '../mixins/object_mixins.dart';
import 'base_context.dart';
import 'response_context.dart';

Type _typeOf<T>() => T;

/// A context that exposes the current request information with a strongly typed body.
class RequestContext<TBody> extends BaseContext {
  /// Creates a [RequestContext] from an already parsed body.
  RequestContext.withBody(
    Request httpRequest,
    TBody? body,
    Map<Type, Provider> providers,
    Map<Type, Object> hooksServices, {
    ModelProvider? modelProvider,
    Type? explicitType,
    bool shouldValidateMultipart = false,
  }) : request = httpRequest,
       _bodyType = explicitType ?? _typeOf<TBody>(),
       _converter = _BodyConverter(modelProvider),
       _body = body,
       shouldValidateMultipart = shouldValidateMultipart,
       super(providers, hooksServices) {
    this.body = _converter.convert(_bodyType, body);
  }

  RequestContext._(
    this.request,
    this._bodyType,
    this._converter,
    TBody? body,
    Map<Type, Provider> providers,
    Map<Type, Object> hooksServices,
    bool shouldValidateMultipart,
  ) : _body = body,
      shouldValidateMultipart = shouldValidateMultipart,
      super(providers, hooksServices);

  /// Creates a [RequestContext] instance reading and converting the request body to [TBody].
  static Future<RequestContext<TBody>> create<TBody>({
    required Request request,
    required Map<Type, Provider> providers,
    required Map<Type, Object> hooksServices,
    required ModelProvider? modelProvider,
    required bool rawBody,
    Type? explicitType,
    bool shouldValidateMultipart = false,
  }) async {
    final converter = _BodyConverter(modelProvider);
    final targetType = explicitType ?? _typeOf<TBody>();
    if (shouldValidateMultipart && request.contentType.isMultipart) {
      return RequestContext._(
        request,
        targetType,
        converter,
        null,
        providers,
        hooksServices,
        shouldValidateMultipart,
      );
    }
    final raw = await request.parseBody(rawBody: rawBody);
    if (explicitType != null) {
      final converted = converter.convert(targetType, raw) as TBody;
      request.body = converted;
    } else {
      request.body = raw;
    }
    return RequestContext._(
      request,
      targetType,
      converter,
      request.body as TBody,
      providers,
      hooksServices,
      shouldValidateMultipart,
    );
  }

  /// The HTTP request object.
  final Request request;

  final Type _bodyType;

  final _BodyConverter _converter;

  /// Indicates whether multipart requests should be validated before accessing the body.
  final bool shouldValidateMultipart;

  TBody? _body;

  /// Returns the request path.
  String get path => request.path;

  /// Returns the request headers.
  SerinusHeaders get headers => request.headers;

  /// Returns the route parameters.
  Map<String, dynamic> get params => request.params;

  /// Returns the query parameters.
  Map<String, dynamic> get query => request.query;

  /// Returns the strongly typed body.
  TBody get body {
    if (_body == null) {
      if (shouldValidateMultipart && request.contentType.isMultipart) {
        throw StateError(
          'The route has been marked with shouldValidateMultipart, use validateMultipartPart<T> before.',
        );
      }
    }
    return _body as TBody;
  }

  /// Access the next part of a multipart request, validating and converting the entire body to [TBody].
  Future<T> validateMultipartPart<T>(
    Future<void> Function(MimeMultipart part)? onPart,
  ) async {
    if (!shouldValidateMultipart || !request.contentType.isMultipart) {
      return bodyAs<T>();
    }
    final formData = await request.parseBody(rawBody: false, onPart: onPart);
    final converted = _converter.convert(_bodyType, formData) as T;
    body = converted;
    request.body = converted;
    return converted;
  }

  /// Replaces the body value ensuring it conforms to [TBody].
  set body(Object? value) {
    _body = _converter.convert(_bodyType, value) as TBody;
    request.body = _body;
  }

  /// Casts the current body to a different type.
  T bodyAs<T>() => _converter.convert(_typeOf<T>(), body) as T;

  /// Casts the current body to a list of a different type.
  List<T> bodyAsList<T>() {
    if (body is! List) {
      throw BadRequestException('The element is not of the expected type');
    }
    return List<T>.from(
      (body as List).map((e) => _converter.convert(_typeOf<T>(), e) as T),
    );
  }

  /// Replaces the underlying body, reusing the conversion rules.
  void replaceBody(Object? value) => body = value;

  /// Retrieves metadata resolved for the request.
  late Map<String, Metadata> metadata;

  /// Response context for manipulating the outgoing response.
  late ResponseContext response;

  /// Shortcut to access the response context.
  ResponseContext get res => response;

  /// Returns a metadata entry by name.
  T stat<T>(String name) {
    if (!canStat(name)) {
      throw StateError('Metadata $name not found in request context');
    }
    return metadata[name]!.value as T;
  }

  /// Determines whether a metadata entry exists.
  bool canStat(String name) => metadata.containsKey(name);

  /// The [operator []] is used to get auxiliary data attached to the request.
  dynamic operator [](String key) => request[key];

  /// The [operator []=] is used to set auxiliary data attached to the request.
  void operator []=(String key, dynamic value) {
    request[key] = value;
  }

  /// Retrieves a query parameter by name, or all parameters if no name is provided.
  /// It tries to convert the parameter to the specified type [T].
  T? queryAs<T>([String? name]) {
    if (name == null) {
      return _converter.convert(_typeOf<T>(), query) as T;
    }
    if (!query.containsKey(name)) {
      return null;
    }
    return _converter.convert(_typeOf<T>(), query[name]) as T;
  }

  /// Retrieves a route parameter by name, or all parameters if no name is provided.
  /// It tries to convert the parameter to the specified type [T].
  T paramAs<T>([String? name]) {
    if (name == null) {
      return _converter.convert(_typeOf<T>(), params) as T;
    }
    final value = params[name];
    if (value == null) {
      final acceptNull = T.runtimeType.toString().endsWith('?');
      if (acceptNull) {
        return value;
      }
      throw ArgumentError('Path parameter $name not found');
    }
    return _converter.convert(_typeOf<T>(), value) as T;
  }
}

final _utf8Decoder = utf8.decoder;

class _BodyConverter {
  const _BodyConverter(this.modelProvider);

  final ModelProvider? modelProvider;

  Object? convert(Type targetType, Object? value) {
    var typeName = targetType.toString();
    if (_isDynamicLike(typeName)) {
      return value;
    }
    final allowsNull = _allowsNull(typeName);
    if (value == null) {
      if (allowsNull) {
        return null;
      }
      throw BadRequestException('Request body is empty');
    }
    if (allowsNull) {
      typeName = typeName.replaceAll('?', '');
    }
    if (typeName == value.runtimeType.toString()) {
      return value;
    }
    switch (typeName) {
      case 'String':
        if (value is String) {
          return value;
        }
        if (value is Uint8List) {
          return _utf8Decoder.convert(value);
        }
        if (value is List<int>) {
          return _utf8Decoder.convert(value);
        }
        if (value is JsonObject) {
          return value.toString();
        }
        if (modelProvider != null) {
          final json =
              modelProvider!.toJsonModels.containsKey(
                value.runtimeType.toString(),
              )
              ? modelProvider!.to(value)
              : null;
          if (json != null) {
            return jsonEncode(json);
          }
        }
        if (value is Map || value is List) {
          return jsonEncode(value);
        }
        break;
      case 'Uint8List':
        if (value is Uint8List) {
          return value;
        }
        if (value is List<int>) {
          return Uint8List.fromList(value);
        }
        if (value is String) {
          return Uint8List.fromList(utf8.encode(value));
        }
        break;
      case 'List<int>':
        if (value is List<int>) {
          return value;
        }
        if (value is List) {
          return List<int>.from(value);
        }
        break;
      case 'int':
        if (value is int) {
          return value;
        }
        if (value is String) {
          return int.parse(value);
        }
        break;
      case 'double':
        if (value is double) {
          return value;
        }
        if (value is int) {
          return value.toDouble();
        }
        if (value is String) {
          return double.parse(value);
        }
        break;
      case 'num':
        if (value is num) {
          return value;
        }
        if (value is String) {
          return num.parse(value);
        }
        break;
      case 'bool':
        if (value is bool) {
          return value;
        }
        if (value is String) {
          final lower = value.toLowerCase();
          if (lower == 'true') {
            return true;
          }
          if (lower == 'false') {
            return false;
          }
        }
        break;
      case 'FormData':
        if (value is FormData) {
          return value;
        }
        break;
    }

    if (_isMapType(typeName)) {
      return _convertToMap(value);
    }
    if (_isListType(typeName)) {
      if (value is! List) {
        throw BadRequestException('The element is not of the expected type');
      }
      if (typeName == 'List<Map<String, dynamic>>') {
        return List<Map<String, dynamic>>.from(
          value.map((e) => _convertToMap(e)),
        );
      }
      if (typeName == 'List<dynamic>') {
        return value;
      }
    }
    if (modelProvider != null) {
      if (value is FormData) {
        final map = {...value.fields, ...value.files};
        return modelProvider!.from(
          '$targetType',
          Map<String, dynamic>.from(map),
        );
      }
      if (value is Map) {
        final mapped = value.map((key, val) => MapEntry('$key', val));
        final result = modelProvider!.from(
          '$targetType',
          Map<String, dynamic>.from(mapped),
        );
        if (allowsNull && result == null) {
          return null;
        }
        return result;
      }
      if (value is List) {
        throw BadRequestException('The element is not of the expected type');
      }
    }
    throw BadRequestException('The element is not of the expected type');
  }

  Map<String, dynamic> _convertToMap(Object value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return value.map((key, val) => MapEntry('$key', val));
    }
    if (value is FormData) {
      return {...value.fields, 'files': value.files};
    }
    if (modelProvider != null) {
      final json =
          modelProvider!.toJsonModels.containsKey(value.runtimeType.toString())
          ? modelProvider!.to(value)
          : null;
      if (json is Map<String, dynamic>) {
        return json;
      }
    }
    throw BadRequestException(
      'The element is not encodable to the correct type',
    );
  }

  static bool _isDynamicLike(String typeName) {
    return typeName == 'dynamic' ||
        typeName == 'Object' ||
        typeName == 'Object?';
  }

  static bool _allowsNull(String typeName) {
    return _isDynamicLike(typeName) || typeName.endsWith('?');
  }

  static bool _isMapType(String typeName) {
    return typeName == 'Map' || typeName.startsWith('Map<');
  }

  static bool _isListType(String typeName) {
    return typeName == 'List' || typeName.startsWith('List<');
  }
}

/// The [Redirect] class is used to create the redirect response.
final class Redirect {
  /// The [location] property contains the location of the redirect.
  final String location;

  /// The [statusCode] property contains the status code of the redirect.
  final int statusCode;

  /// The [Redirect] constructor.
  const Redirect(
    this.location, {
    this.statusCode = HttpStatus.movedTemporarily,
  });
}
