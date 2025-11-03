import '../mixins/object_mixins.dart';

/// Exception class for RPC errors.
class RpcException with JsonObject implements Exception {
  /// The error message.
  final String message;

  /// The pattern associated with the RPC error.
  final String pattern;

  /// Optional identifier for the RPC error.
  final String? id;

  /// Constructor for the [RpcException] class.
  RpcException(this.message, this.pattern, {this.id});

  @override
  Map<String, dynamic> toJson() {
    return {'message': message, 'pattern': pattern, if (id != null) 'id': id};
  }

  /// Creates a copy of the current [RpcException] with optional new values.
  RpcException copyWith({String? message, String? pattern, String? id}) {
    return RpcException(
      message ?? this.message,
      pattern ?? this.pattern,
      id: id ?? this.id,
    );
  }
}
