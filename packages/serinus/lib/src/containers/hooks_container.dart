import '../core/hook.dart';
import '../core/websockets/ws_mixins_hook.dart';
import '../mixins/hooks_mixins.dart';

/// The [HooksContainer] class is used to manage hooks in the application.
final class HooksContainer {

  /// The set of hooks registered in the container
  final Set<Type> hooks = {};
  
  /// The request response hooks for the container
  final Set<OnRequest> reqHooks = {};

  /// The request response hooks for the container
  final Set<OnResponse> resHooks = {};

  /// The before hooks for the container
  final Set<OnBeforeHandle> beforeHooks = {};

  /// The after hooks for the container
  final Set<OnAfterHandle> afterHooks = {};

  /// The exception hooks for the container
  final Set<OnException> exceptionHooks = {};

  /// The web socket request hooks for the container
  final Set<OnBeforeMessage> beforeMessageHooks = {};

  /// The web socket upgrade hooks for the container
  final Set<OnUpgrade> upgradeHooks = {};

  /// The web socket close hooks for the container
  final Set<OnClose> closeHooks = {};

  /// The web socket exception hooks for the container
  final Set<OnWsException> wsExceptionHooks = {};

  /// The services exposed by the hooks
  final Map<Type, Object> services = {};

  /// Add a hook to the container
  void addHook(Hook hook) {
    if (hook is OnRequest) {
      reqHooks.add(hook);
    }
    if (hook is OnBeforeHandle) {
      beforeHooks.add(hook as OnBeforeHandle);
    }
    if (hook is OnAfterHandle) {
      afterHooks.add(hook as OnAfterHandle);
    }
    if (hook is OnException) {
      exceptionHooks.add(hook);
    }
    if (hook is OnResponse) {
      resHooks.add(hook);
    }
    if (hook is OnBeforeMessage) {
      beforeMessageHooks.add(hook);
    }
    if (hook is OnUpgrade) {
      upgradeHooks.add(hook);
    }
    if (hook is OnClose) {
      closeHooks.add(hook);
    }
    if (hook is OnWsException) {
      wsExceptionHooks.add(hook);
    }
    if (hook.service != null) {
      services[hook.service!.runtimeType] = hook.service!;
    }
    hooks.add(hook.runtimeType);
  }

  /// Merge multiple hooks containers into one
  HooksContainer merge(List<HooksContainer> containers) {
    final merged = HooksContainer();
    for (final container in containers) {
      merged.reqHooks.addAll(container.reqHooks.where((e) => !merged.hooks.contains(e.runtimeType)));
      merged.resHooks.addAll(container.resHooks.where((e) => !merged.hooks.contains(e.runtimeType)));
      merged.beforeHooks.addAll(container.beforeHooks.where((e) => !merged.hooks.contains(e.runtimeType)));
      merged.afterHooks.addAll(container.afterHooks.where((e) => !merged.hooks.contains(e.runtimeType)));
      merged.exceptionHooks.addAll(container.exceptionHooks.where((e) => !merged.hooks.contains(e.runtimeType)));
      for (final service in container.services.entries) {
        if (!merged.services.containsKey(service.key)) {
          merged.services[service.key] = service.value;
        }
      }
    }
    return merged;
  }
}
