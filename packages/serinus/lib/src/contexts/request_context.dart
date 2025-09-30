import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import '../containers/model_provider.dart';
import '../core/core.dart';
import '../exceptions/exceptions.dart';
import '../http/http.dart';
import 'base_context.dart';
import 'response_context.dart';

Type _typeOf<T>() => T;

/// A context that exposes the current request information with a strongly typed body.
class RequestContext<TBody> extends BaseContext {
  /// Creates a [RequestContext] from an already parsed body.
  RequestContext.withBody(
    Request httpRequest,
    TBody body,
    Map<Type, Provider> providers,
    Map<Type, Object> hooksServices, {
    ModelProvider? modelProvider,
    Type? explicitType,
  }) : request = httpRequest,
       _bodyType = explicitType ?? _typeOf<TBody>(),
       _converter = _BodyConverter(modelProvider),
       _body = body,
       super(providers, hooksServices) {
    this.body = body;
  }

  RequestContext._(
    this.request,
    this._bodyType,
    this._converter,
    TBody body,
    Map<Type, Provider> providers,
    Map<Type, Object> hooksServices,
  ) : _body = body,
      super(providers, hooksServices);

  /// Creates a [RequestContext] instance reading and converting the request body to [TBody].
  static Future<RequestContext<TBody>> create<TBody>({
    required Request request,
    required Map<Type, Provider> providers,
    required Map<Type, Object> hooksServices,
    required ModelProvider? modelProvider,
    required bool rawBody,
    Type? explicitType,
  }) async {
    final converter = _BodyConverter(modelProvider);
    final targetType = explicitType ?? _typeOf<TBody>();
    final raw = await request.parseBody(rawBody: rawBody);
    final converted = converter.convert(targetType, raw) as TBody;
    request.body = converted;
    return RequestContext._(
      request,
      targetType,
      converter,
      converted,
      providers,
      hooksServices,
    );
  }

  /// The HTTP request object.
  final Request request;

  final Type _bodyType;
  final _BodyConverter _converter;

  TBody _body;

  /// Returns the request path.
  String get path => request.path;

  /// Returns the request headers.
  SerinusHeaders get headers => request.headers;

  /// Returns the route parameters.
  Map<String, dynamic> get params => request.params;

  /// Returns the query parameters.
  Map<String, dynamic> get query => request.query;

  /// Returns the strongly typed body.
  TBody get body => _body;

  /// Replaces the body value ensuring it conforms to [TBody].
  set body(Object? value) {
    _body = _converter.convert(_bodyType, value) as TBody;
    request.body = _body;
  }

  /// Casts the current body to a different type.
  T bodyAs<T>() => _converter.convert(_typeOf<T>(), body) as T;

  /// Replaces the underlying body, reusing the conversion rules.
  void replaceBody(Object? value) => body = value;

  /// Retrieves metadata resolved for the request.
  late Map<String, Metadata> metadata;

  /// Response context for manipulating the outgoing response.
  late ResponseContext response;

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
  T? paramAs<T>([String? name]) {
    if (name == null) {
      return _converter.convert(_typeOf<T>(), params) as T;
    }
    if (!params.containsKey(name)) {
      return null;
    }
    return _converter.convert(_typeOf<T>(), params[name]) as T;
  }
}

class _BodyConverter {
  const _BodyConverter(this.modelProvider);

  final ModelProvider? modelProvider;

  Object? convert(Type targetType, Object? value) {
    final typeName = targetType.toString();
    if (_isDynamicLike(typeName)) {
      return value;
    }

    if (value == null) {
      if (_allowsNull(typeName)) {
        return null;
      }
      throw PreconditionFailedException('Request body is empty');
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
          return utf8.decode(value);
        }
        if (value is List<int>) {
          return utf8.decode(value);
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
        throw PreconditionFailedException(
          'Element cannot be converted to List',
        );
      }
      final elementName = _extractListElement(typeName);
      if (elementName == null || _isDynamicLike(elementName)) {
        return value;
      }
      return value.map((e) => convert(_RuntimeType(elementName), e)).toList();
    }

    if (modelProvider != null) {
      if (value is FormData) {
        final map = {...value.fields, ...value.files};
        return modelProvider!.from(targetType, Map<String, dynamic>.from(map));
      }
      if (value is Map) {
        final mapped = value.map((key, val) => MapEntry('$key', val));
        return modelProvider!.from(
          targetType,
          Map<String, dynamic>.from(mapped),
        );
      }
      if (value is List) {
        final elementName = _extractListElement(typeName);
        if (elementName != null && elementName.isNotEmpty) {
          return value
              .map((e) => convert(_RuntimeType(elementName), e))
              .toList();
        }
      }
    }

    throw PreconditionFailedException('The type is not supported: $targetType');
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
    throw PreconditionFailedException('The body is not a map');
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

  static String? _extractListElement(String typeName) {
    final start = typeName.indexOf('<');
    final end = typeName.lastIndexOf('>');
    if (start == -1 || end == -1 || end <= start + 1) {
      return null;
    }
    return typeName.substring(start + 1, end);
  }
}

/// Helper runtime type used when a generic type argument is only available as a string.
class _RuntimeType implements Type {
  const _RuntimeType(this._repr);
  final String _repr;

  @override
  String toString() => _repr;
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
