import 'package:acanthis/acanthis.dart';
import '../exceptions/exceptions.dart';

/// The [ParseSchema] class is used to define the schema of the parsing process.
abstract class ParseSchema<R, BodyType, MapType> {
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
  const ParseSchema({
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
  Future<R> tryParse({
    Object? bodyValue,
    Map<String, dynamic>? queryValue,
    Map<String, dynamic>? paramsValue,
    Map<String, dynamic>? headersValue,
    Map<String, dynamic>? sessionValue,
  });
}

/// The [AcanthisParseSchema] class is used to define the schema of the parsing process using the [Acanthis] library.
@Deprecated('Use pipes instead')
class AcanthisParseSchema extends ParseSchema<AcanthisParseResult, AcanthisType, AcanthisMap> {

  /// The [AcanthisParseSchema] constructor is used to create a new instance of the [AcanthisParseSchema] class.
  const AcanthisParseSchema({
    super.body,
    super.query,
    super.params,
    super.headers,
    super.session,
    super.error,
  });

  @override
  Future<AcanthisParseResult> tryParse({
    Object? bodyValue,
    Map<String, dynamic>? queryValue,
    Map<String, dynamic>? paramsValue,
    Map<String, dynamic>? headersValue,
    Map<String, dynamic>? sessionValue,
  }) async {
    final AcanthisParseResult result = AcanthisParseResult();
    if(body != null) {
      final value = body!.tryParse(bodyValue);
      result.body = value.value;
      if(value.errors.isNotEmpty) {
        throw error?.call(value.errors) ?? BadRequestException('Body value is invalid');
      }
    }
    if(query != null) {
      final value = query!.tryParse(queryValue ?? {});
      result.query = value.value;
      if(value.errors.isNotEmpty) {
        throw error?.call(value.errors) ?? BadRequestException('Query value is invalid');
      }
    }
    if(params != null) {
      final value = params!.tryParse(paramsValue ?? {});
      result.params = value.value;
      if(value.errors.isNotEmpty) {
        throw error?.call(value.errors) ?? BadRequestException('Params value is invalid');
      }
    }
    if(headers != null) {
      final value = headers!.tryParse(headersValue ?? {});
      result.headers = value.value;
      if(value.errors.isNotEmpty) {
        throw error?.call(value.errors) ?? BadRequestException('Headers value is invalid');
      }
    }
    if(session != null) {
      final value = session!.tryParse(sessionValue ?? {});
      result.session = value.value;
      if(value.errors.isNotEmpty) {
        throw error?.call(value.errors) ?? BadRequestException('Session value is invalid');
      }
    }
    return result;
  }
}

class AcanthisParseResult {
  Object? body;

  Map<String, dynamic>? query;

  Map<String, dynamic>? params;

  Map<String, dynamic>? headers;

  Map<String, dynamic>? session;

  AcanthisParseResult({
    this.body,
    this.query,
    this.params,
    this.headers,
    this.session,
  });
}