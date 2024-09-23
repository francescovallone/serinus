import '../contexts/request_context.dart';
import '../exceptions/exceptions.dart';

/// The [ResponseEvent] enum is used to define the different events that can be listened to on a response.
///
/// The events are:
/// - [ResponseEvent.close]: The response has been closed.
/// - [ResponseEvent.data]: Data has been sent to the response.
enum RequestEvent {
  
  /// The request has been closed.
  close,

  /// Data has been sent to the response.
  data,

  /// A redirect has been sent to the response.
  redirect,

  /// An error has occurred.
  error,

  /// All events.
  all
}

/// The [ResponseProperties] class is used to store the properties of a response.
class EventData {

  /// The [hasException] property contains a boolean value that indicates if the event contains an error.
  /// 
  /// - If statusCode >= 400, isError is true.
  /// - If exception is not null, isError is true.
  bool get hasException => exception != null || properties.statusCode >= 400;

  /// The [exception] property contains the exception that occurred.
  final SerinusException? exception;

  /// The [data] property contains the response data.
  final Object? data;

  /// The [ResponseProperties] property contains the properties of the response it is copied from the request.
  final ResponseProperties properties;

  /// The [EventData] class is used to store the data of an event.
  const EventData({
    required this.data,
    required this.properties,
    this.exception,
  });

}