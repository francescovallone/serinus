/// Supported generic annotation kinds for analyzer-driven custom annotations.
enum OpenApiAnnotationKind {
  /// Request body annotation payload.
  body,

  /// Single response annotation payload.
  response,

  /// Multiple responses annotation payload.
  responses,

  /// Query parameters annotation payload.
  query,

  /// Operation id annotation payload.
  operationId,
}

/// OpenApiAnnotation is the base class for all OpenAPI annotations.
abstract class OpenApiAnnotation {
  /// Analyzer dispatch kind for custom annotations.
  ///
  /// Supported generic kinds are declared in [OpenApiAnnotationKind].
  final OpenApiAnnotationKind? analyzerKind;

  /// Analyzer payload for custom annotations.
  ///
  /// This should be a const map so it can be read from static analysis.
  final Map<Object?, Object?>? analyzerSpec;

  /// Creates a new OpenApiAnnotation. This is a const constructor, so it can be used in const contexts.
  const OpenApiAnnotation({this.analyzerKind, this.analyzerSpec});

  /// Converts the annotation to an OpenAPI specification map.
  Map<String, dynamic> toOpenApiSpec();
}
