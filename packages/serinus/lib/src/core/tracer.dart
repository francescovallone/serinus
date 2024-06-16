import '../../serinus.dart';

/// Base class for all tracers.
abstract class Tracer {

  /// The [name] of the [Tracer]
  final String name;

  /// Creates a new [Tracer] with the given [name].
  Tracer(this.name);

  /// The [Object] that started the [Tracer]
  void startTracing();

  /// Called to trace the onRequest event
  Future<void> onRequest(Request request) async {}

  /// Called to trace the onTransform event
  Future<void> onTranform(RequestContext context) async {}

  /// Called to trace the onParse event
  Future<void> onParse(RequestContext context) async {}

  /// Called to trace the onMiddlewares event
  Future<void> onMiddlewares(RequestContext context) async {}

  /// Called to trace the onBeforeHandle event
  Future<void> onBeforeHandle(RequestContext context) async {}

  /// Called to trace the onHandle event
  Future<void> onHandle(RequestContext context) async {}

  /// Called to trace the onAfterHandle event
  Future<void> onAfterHandle(RequestContext context) async {}

  /// Called to trace the onResponse event
  Future<void> onResponse(Response response) async {}

}