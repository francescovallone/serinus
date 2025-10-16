import '../../mixins/mixins.dart';

/// Exception class for WebSocket errors.
class WsException with JsonObject implements Exception {
  /// The WebSocket error code.
  final int code;

  /// The WebSocket error message.
  final String message;

  /// Constructor for the [WsException] class.
  const WsException({required this.code, required this.message});

  @override
  Map<String, dynamic> toJson() {
    return {'code': code, 'message': message};
  }

  /// Creates a copy of the current [WsException] with optional new values.
  WsException copyWith({String? message, int? code}) {
    return WsException(
      code: code ?? this.code,
      message: message ?? this.message,
    );
  }
}

/// Indicates that an endpoint is terminating the connection because it has
/// received a frame that is not consistent with the type of the message.
class ProtocolErrorException extends WsException {
  /// Constructor for [ProtocolErrorException].
  const ProtocolErrorException({super.message = 'Protocol Error'})
    : super(code: 1002);
}

/// Indicates that an endpoint is terminating the connection because it has
/// received a type of data it cannot accept (e.g., an endpoint that understands
/// only text data MAY send this if it receives a binary message).
class UnsupportedDataException extends WsException {
  /// Constructor for [UnsupportedDataException].
  const UnsupportedDataException({super.message = 'Unsupported Data'})
    : super(code: 1003);
}

/// Indicates that an endpoint is terminating the connection because it has
/// received a type of data it cannot accept (e.g., an endpoint that understands
/// only text data MAY send this if it receives a binary message).
class InvalidFramePayloadDataException extends WsException {
  /// Constructor for [InvalidFramePayloadDataException].
  const InvalidFramePayloadDataException({
    super.message = 'Invalid Frame Payload Data',
  }) : super(code: 1007);
}

/// Indicates that the server is terminating the connection because it has
/// received a message that violates its policy. This is a generic status code
/// that can be returned when there is no other more suitable status code (e.g.,
/// 1003 or 1009) or if there is a need to hide specific details about the policy.
class PolicyViolationException extends WsException {
  /// Constructor for [PolicyViolationException].
  const PolicyViolationException({super.message = 'Policy Violation'})
    : super(code: 1008);
}

/// Indicates that the server is terminating the connection because it has
/// received a message that is too big for it to process.
class MessageTooBigException extends WsException {
  /// Constructor for [MessageTooBigException].
  const MessageTooBigException({super.message = 'Message Too Big'})
    : super(code: 1009);
}

/// Indicates that the server is terminating the connection because it requires
/// the client to negotiate one or more extensions, but the client did not
/// include the necessary extension(s) in its handshake.
class MandatoryExtensionException extends WsException {
  /// Constructor for [MandatoryExtensionException].
  const MandatoryExtensionException({super.message = 'Mandatory Extension'})
    : super(code: 1010);
}

/// Indicates that the server is terminating the connection because it encountered
/// an unexpected condition that prevented it from fulfilling the request.
class InternalServerErrorException extends WsException {
  /// Constructor for [InternalServerErrorException].
  const InternalServerErrorException({super.message = 'Internal Server Error'})
    : super(code: 1011);
}
