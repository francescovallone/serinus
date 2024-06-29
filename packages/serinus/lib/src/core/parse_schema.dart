import 'dart:convert';

import 'package:acanthis/acanthis.dart';

import '../exceptions/exceptions.dart';

/// The [ParseSchema] class is used to define the schema of the parsing process.
final class ParseSchema {
  late AcanthisMap _schema;

  /// The [error] property contains the error that will be thrown if the parsing fails.
  final SerinusException Function(Map<String, dynamic>)? error;

  /// The [ParseSchema] constructor is used to create a new instance of the [ParseSchema] class.
  ParseSchema(
      {AcanthisType? body,
      AcanthisMap? query,
      AcanthisMap? params,
      AcanthisMap? headers,
      AcanthisMap? session,
      this.error}) {
    _schema = object({
      if (body != null) 'body': body is AcanthisMap ? body.passthrough() : body,
      if (query != null) 'query': query.passthrough(),
      if (params != null) 'params': params.passthrough(),
      if (headers != null) 'headers': headers.passthrough(),
      if (session != null) 'session': session.passthrough(),
    }).passthrough();
  }

  /// The [tryParse] method is used to validate the data.
  Map<String, dynamic> tryParse({required Map<String, dynamic> value}) {
    AcanthisParseResult? result;
    try {
      result = _schema.tryParse(value);
    } catch (error) {
      throw PreconditionFailedException(message: 'Wrong data format');
    }
    if (!result.success) {
      throw error?.call(result.errors) ??
          BadRequestException(message: jsonEncode(result.errors));
    }
    return result.value;
  }
}
