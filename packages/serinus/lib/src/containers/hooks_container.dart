import '../core/hook.dart';
import '../mixins/hooks_mixins.dart';

/// The hooks container for the application
final class HooksContainer {
  /// The request response hooks for the application
  final Set<OnRequestResponse> reqResHooks = {};

  /// The before hooks for the application
  final Set<OnBeforeHandle> beforeHooks = {};

  /// The after hooks for the application
  final Set<OnAfterHandle> afterHooks = {};

  /// The exception hooks for the application
  final Set<OnException> exceptionHooks = {};

  /// The services exposed by the hooks
  final Map<Type, Object> services = {};

  /// Add a hook to the application
  void addHook(Hook hook) {
    if (hook is OnRequestResponse) {
      reqResHooks.add(hook);
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
    if (hook.service != null) {
      services[hook.service!.runtimeType] = hook.service!;
    }
  }

  HooksContainer merge(List<HooksContainer> containers) {
    final merged = HooksContainer();
    for (final container in containers) {
      merged.reqResHooks.addAll(container.reqResHooks);
      merged.beforeHooks.addAll(container.beforeHooks);
      merged.afterHooks.addAll(container.afterHooks);
      merged.exceptionHooks.addAll(container.exceptionHooks);
      merged.services.addAll(container.services);
    }
    return merged;
  }
}
