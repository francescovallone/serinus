import 'component.dart';

/// Represents a descriptive object in the OpenAPI specification.
abstract class DescriptiveObject extends ComponentValue {
  @override
  Map<String, dynamic> toJson();
}
