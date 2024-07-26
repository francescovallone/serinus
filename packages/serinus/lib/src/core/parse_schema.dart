import 'dart:convert';
import 'dart:isolate';

import 'package:acanthis/acanthis.dart';

import '../exceptions/exceptions.dart';

/// The [ParseSchema] class is used to define the schema of the parsing process.
abstract class ParseSchema<MapType, BodyType> {
  /// The [body] property contains the schema of the body.
  final BodyType? body;

  /// The [query] property contains the schema of the query.
  final MapType? query;

  /// The [params] property contains the schema of the params.
  final MapType? params;

  /// The [headers] property contains the schema of the headers.
  final MapType? headers;

  /// The [session] property contains the schema of the session.
  final MapType? session;

  /// The [error] property contains the error that will be thrown if the parsing fails.
  final SerinusException Function(Map<String, dynamic>)? error;

  /// The [ParseSchema] constructor is used to create a new instance of the [ParseSchema] class.
  ParseSchema({
    this.body,
    this.query,
    this.params,
    this.headers,
    this.session,
    this.error,
  });

  /// The [tryParse] method is used to validate the data.
  ///
  /// The method returns the parsed data if the data is valid.
  ///
  /// The method throws a [SerinusException] if the data is invalid.
  Future<Map<String, dynamic>> tryParse({required Map<String, dynamic> value});
}

/// The [AcanthisParseSchema] class is used to define the schema of the parsing process using the [Acanthis] library.
class AcanthisParseSchema extends ParseSchema<AcanthisMap, AcanthisType> {
  late final AcanthisMap _schema;

  /// The [AcanthisParseSchema] constructor is used to create a new instance of the [AcanthisParseSchema] class.
  AcanthisParseSchema({
    super.body,
    super.query,
    super.params,
    super.headers,
    super.session,
    super.error,
  }) {
    _schema = object({
      if (body != null)
        'body':
            (body is AcanthisMap) ? (body as AcanthisMap).passthrough() : body!,
      if (query != null) 'query': query!.passthrough(),
      if (params != null) 'params': params!.passthrough(),
      if (headers != null) 'headers': headers!.passthrough(),
      if (session != null) 'session': session!.passthrough(),
    }).passthrough();
  }

  @override
  Future<Map<String, dynamic>> tryParse(
      {required Map<String, dynamic> value}) async {
    return Isolate.run<Map<String, dynamic>>(() {
      try {
        AcanthisParseResult result = _schema.tryParse(value);
        if (!result.success) {
          throw error?.call(result.errors) ??
              BadRequestException(message: jsonEncode(result.errors));
        }
        return result.value;
      } on SerinusException catch (_) {
        rethrow;
      } catch (_) {
        throw PreconditionFailedException(message: 'Wrong data format');
      }
    });
  }
}
