import 'dart:io';

import '../http/http.dart';

/// A body parser for a specific content type.
abstract class BodyParser<T> {

  /// The content types that this parser can handle.
  List<ContentType> get supportedContentTypes;

  /// Parse the request body.
  Future<T> parse(IncomingMessage request);

  /// Check if the parser can handle a specific content type.
  bool canParse(ContentType contentType) {
    return supportedContentTypes.any((type) => 
      type.primaryType == contentType.primaryType && 
      type.subType == contentType.subType
    );
  }

  /// The content type that this parser can handle.
  String get contentType;

}

/// A registry for body parsers.
class BodyParserRegistry {

  final Map<String, BodyParser> _parsers = {};

  /// Register a body parser for a specific content type
  void register<T>(BodyParser<T> parser) {
    for (final contentType in parser.supportedContentTypes) {
      final key = '${contentType.primaryType}/${contentType.subType}';
      _parsers[key] = parser;
    }
  }

  /// Get a body parser for a specific content type
  BodyParser<T>? get<T>(ContentType contentType) {
    final key = '${contentType.primaryType}/${contentType.subType}';
    return _parsers[key] as BodyParser<T>?;
  }

}