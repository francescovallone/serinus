import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:mime/mime.dart';

import '../../serinus.dart';
import '../containers/models_provider.dart';
import '../core/core.dart';
import '../exceptions/exceptions.dart';
import '../extensions/content_type_extensions.dart';
import '../http/http.dart';
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
    this.body = body;
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

abstract class TypeConverter<E> {
  E fromValue(Object? input);
}

class IdentityConverter<E> extends TypeConverter<E> {
  @override
  E fromValue(Object? input) => input as E;
}

class ConverterRegistry {
  // Map by Type (preferred) and by String name (fallback).
  static final Map<Type, TypeConverter<dynamic>> _byType = {};
  static final Map<String, TypeConverter<dynamic>> _byName = {};

  static void registerType<E>(TypeConverter<E> converter) {
    _byType[E] = converter;
    _byName[_typeName(E)] = converter;
  }

  static TypeConverter<E>? getByType<E>(Type type) {
    return _byType[type] as TypeConverter<E>?;
  }

  static TypeConverter<E>? getByName<E>(String name) {
    final conv = _byName[name];
    return conv as TypeConverter<E>?;
  }

  static String _typeName(Object t) => t.toString();
}

/// Try to extract the inner generic parameter name from "List<Something>"
String? _extractListElementTypeNameFromTypeString(String tStr) {
  // Basic parser: finds the top-level <...> inside the string and returns content.
  final start = tStr.indexOf('<');
  final end = tStr.lastIndexOf('>');
  if (start == -1 || end == -1 || end <= start + 1) {
    return null;
  }
  final inner = tStr.substring(start + 1, end).trim();
  return inner.isEmpty ? null : inner;
}

/// The main generic function user asked for.
T convertList<T>(Object? value) {
  // Expect T to be something like List<E>
  final runtimeType = _typeOf<T>();
  final typeString = runtimeType.toString();

  // If the runtime type string is just 'List' without generic args, no luck
  final elemTypeName = _extractListElementTypeNameFromTypeString(typeString);

  // If we can resolve a Type converter by Type directly, prefer that.
  // Try to guess element type by parsing the string and looking up registry by name.
  List<dynamic> converted;

  if (value is! List) {
    // Not a list: return empty list of correct typed List
    converted = <dynamic>[];
  } else {
    // Best-effort: 1) try exact Type lookup for List<E> -> not helpful for elements
    // 2) parse element type name and look up converter by name
    TypeConverter? elemConverter;

    if (elemTypeName != null) {
      // Try direct by name
      elemConverter = ConverterRegistry.getByName(elemTypeName);
      // If name lookup fails, also try infer common dart types:
      if (elemConverter == null) {
        if (elemTypeName == 'int') elemConverter = IdentityConverter<int>();
        if (elemTypeName == 'double') elemConverter = IdentityConverter<double>();
        if (elemTypeName == 'String') elemConverter = IdentityConverter<String>();
        if (elemTypeName == 'bool') elemConverter = IdentityConverter<bool>();
      }
    }

    if (elemConverter != null) {
      converted = value.map((e) => elemConverter!.fromValue(e)).toList();
    } else {
      // Last resort: try to cast each element to the expected element type by
      // using a runtime Type for element if we can recover it (this is fragile)
      // We'll try to derive a Type from the name if the registry has one
      converted = value.cast<dynamic>().toList();
    }
  }

  // Cast the list to T — if T is List<E> this will be a runtime cast.
  return converted as T;
}

/// Robust explicit alternative: caller supplies element-type via generic parameter
List<E> convertListWith<E>(Object? value) {
  if (value is! List) {
    return <E>[];
  }
  final conv = ConverterRegistry.getByType<E>(E);
  if (conv != null) {
    return value.map((e) => conv.fromValue(e)).toList();
  }
  // fallback to cast
  return value.cast<E>().toList();
}

final _utf8Decoder = utf8.decoder;

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
      throw BadRequestException('Request body is empty');
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
          final json = modelProvider!.toJsonModels.containsKey(value.runtimeType.toString())
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
        throw BadRequestException(
          'The element is not of the expected type',
        );
      }
    }
    if (modelProvider != null) {
      if (value is FormData) {
        final map = {...value.fields, ...value.files};
        return modelProvider!.from('$targetType', Map<String, dynamic>.from(map));
      }
      if (value is Map) {
        final mapped = value.map((key, val) => MapEntry('$key', val));
        return modelProvider!.from(
          '$targetType',
          Map<String, dynamic>.from(mapped),
        );
      }
      if (value is List) {
        throw BadRequestException(
          'The element is not of the expected type',
        );
      }
    }
    throw BadRequestException(
      'The element is not of the expected type',
    );
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
      final json = modelProvider!.toJsonModels.containsKey(value.runtimeType)
          ? modelProvider!.to(value)
          : null;
      if (json is Map<String, dynamic>) {
        return json;
      }
    }
    throw BadRequestException('The element is not encodable to the correct type');
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
