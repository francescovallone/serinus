/// The [ResponseEvent] enum is used to define the different events that can be listened to on a response.
///
/// The events are:
/// - [ResponseEvent.close]: The response has been closed.
/// - [ResponseEvent.data]: Data has been sent to the response.
enum ResponseEvent {
  /// The response has been closed.
  close,

  /// Data is being sent to the response.
  beforeSend,

  /// Data has been sent to the response.
  data,

  /// The response has been sent.
  afterSend,

  /// A redirect has been sent to the response.
  redirect,

  /// An error has occurred.
  error,

  /// All events.
  all
}
