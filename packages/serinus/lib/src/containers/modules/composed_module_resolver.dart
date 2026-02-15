import '../../core/core.dart';
import '../../errors/initialization_error.dart';
import '../injection_token.dart';
import 'scope_manager.dart';

/// Resolves composed modules by initializing them when dependencies are available.
///
/// The [ComposedModuleResolver] is responsible for:
/// - Tracking composed modules pending initialization
/// - Resolving dependencies for composed modules
/// - Initializing modules when all dependencies are satisfied
/// - Propagating exports to parent modules
class ComposedModuleResolver {
  /// Scope manager for scope operations
  final ScopeManager _scopeManager;

  /// Map of parent tokens to their pending composed modules
  final Map<InjectionToken, List<ComposedModuleEntry>> _composedModules = {};

  /// Callback to register a new module
  final Future<void> Function(Module, {bool internal, int depth})
  _registerModule;

  /// Creates a new composed module resolver
  ComposedModuleResolver(this._scopeManager, this._registerModule);

  int _nextDepthFor(InjectionToken parentToken) {
    final parentScope = _scopeManager.getScopeOrNull(parentToken);
    if (parentScope == null || !parentScope.distance.isFinite) {
      return 1;
    }
    return parentScope.distance.toInt() + 1;
  }

  /// Adds a composed module entry for a parent token
  void addPending(InjectionToken parentToken, ComposedModuleEntry entry) {
    final entries = _composedModules.putIfAbsent(parentToken, () => []);
    entries.add(entry);
  }

  /// Gets all pending (uninitialized) composed modules
  List<ComposedModuleEntry> getPendingModules() {
    return _composedModules.values
        .expand((entries) => entries)
        .where((entry) => !entry.isInitialized)
        .toList();
  }

  /// Checks if there are any pending composed modules
  bool get hasPending => _composedModules.isNotEmpty;

  /// Gets pending entries for a specific token
  List<ComposedModuleEntry>? getEntries(InjectionToken token) =>
      _composedModules[token];

  /// Cleans up resolved composed modules from tracking
  void cleanupResolved() {
    for (final token in _composedModules.keys.toList()) {
      final pending = _composedModules[token]!
          .where((entry) => !entry.isInitialized)
          .toList();
      if (pending.isEmpty) {
        _composedModules.remove(token);
      } else {
        _composedModules[token] = pending;
      }
    }
  }

  /// Calculates missing dependencies for a composed module
  Set<Type> getMissingDependencies(
    Iterable<Type> inject,
    Iterable<Provider> availableProviders, [
    Map<ValueToken, Object?> availableValues = const {},
  ]) {
    final availableTypes = availableProviders.map((e) => e.runtimeType).toSet();
    // Get value types from unnamed value tokens for dependency matching
    final valueTypes = availableValues.keys
        .where((token) => token.name == null)
        .map((token) => token.type)
        .toSet();
    final missing = <Type>{};
    for (final dependency in inject) {
      if (!availableTypes.contains(dependency) &&
          !valueTypes.contains(dependency)) {
        missing.add(dependency);
      }
    }
    return missing;
  }

  /// Initializes composed modules once their dependencies are satisfied.
  ///
  /// Returns true if any progress was made
  Future<bool> initializeComposedModules() async {
    if (_composedModules.isEmpty) {
      return false;
    }

    bool progress = false;

    // Take a snapshot to iterate safely
    final snapshots = _composedModules.entries
        .map(
          (entry) => (
            token: entry.key,
            modules: List<ComposedModuleEntry>.from(entry.value),
          ),
        )
        .toList();

    for (final snapshot in snapshots) {
      final parentScope = _scopeManager.getScopeOrNull(snapshot.token);
      if (parentScope == null) {
        continue;
      }

      for (final entry in snapshot.modules) {
        if (entry.isInitialized) {
          continue;
        }

        final initialized = await initializeEntry(entry, snapshot.token);
        if (initialized) {
          progress = true;
        }
      }
    }

    cleanupResolved();
    return progress;
  }

  /// Initializes a single composed module entry.
  ///
  /// Returns true if the module was initialized, false when dependencies are missing.
  Future<bool> initializeEntry(
    ComposedModuleEntry entry,
    InjectionToken parentToken,
  ) async {
    if (entry.isInitialized) {
      return false;
    }

    final parentScope = _scopeManager.getScopeOrNull(parentToken);
    if (parentScope == null) {
      throw InitializationError('Module with token $parentToken not found');
    }

    final missing = getMissingDependencies(
      entry.module.inject,
      parentScope.unifiedProviders,
      parentScope.unifiedValues,
    );
    entry.missingDependencies
      ..clear()
      ..addAll(missing);

    if (missing.isNotEmpty) {
      return false;
    }

    final stopwatch = Stopwatch()..start();
    final context = _scopeManager.buildCompositionContext(
      parentScope.unifiedProviders,
      parentScope.unifiedValues,
    );
    final dynamic resolvedModule = await entry.module.init(context);
    if (stopwatch.isRunning) {
      stopwatch.stop();
    }

    if (resolvedModule is! Module) {
      throw InitializationError(
        '[${entry.parentModule.runtimeType}] ${entry.module.runtimeType} '
        'did not return a Module instance.',
      );
    }

    final moduleInstance = resolvedModule;
    entry.isInitialized = true;
    entry.missingDependencies.clear();

    await _registerModule(
      moduleInstance,
      internal: true,
      depth: _nextDepthFor(parentToken),
    );

    final refreshedParentScope = _scopeManager.getScopeOrNull(parentToken);
    if (refreshedParentScope == null) {
      throw InitializationError('Module with token $parentToken not found');
    }

    refreshedParentScope.imports.add(moduleInstance);
    if (!refreshedParentScope.module.imports.contains(moduleInstance)) {
      refreshedParentScope.module.imports = [
        ...refreshedParentScope.module.imports,
        moduleInstance,
      ];
    }

    final subModuleToken = InjectionToken.fromModule(moduleInstance);
    final subModuleScope = _scopeManager.getScopeOrNull(subModuleToken);
    if (subModuleScope == null) {
      throw InitializationError('Module with token $subModuleToken not found');
    }

    if (!subModuleScope.module.isGlobal) {
      subModuleScope.distance = _nextDepthFor(parentToken).toDouble();
    }

    subModuleScope.composed = true;
    subModuleScope.initTime = stopwatch.elapsedMicroseconds;
    subModuleScope.importedBy.add(parentToken);

    return true;
  }

  /// Creates an error message for unresolved composed modules
  String createUnresolvedError() {
    final unresolvedModules = getPendingModules();
    if (unresolvedModules.isEmpty) {
      return '';
    }

    final buffer = StringBuffer(
      'Cannot resolve composed modules due to missing dependencies:\n',
    );

    for (final entry in unresolvedModules) {
      final scope = _scopeManager.getScopeOrNull(entry.parentToken);
      final availableProviders = scope?.unifiedProviders ?? const <Provider>{};
      final availableValues =
          scope?.unifiedValues ?? const <ValueToken, Object?>{};
      final missing = getMissingDependencies(
        entry.module.inject,
        availableProviders,
        availableValues,
      );
      final dependencies = missing.isEmpty
          ? entry.module.inject
          : missing.toList();
      buffer.writeln(
        ' - ${entry.module.runtimeType}: '
        '[${dependencies.map((e) => e.toString()).join(', ')}]',
      );
    }

    return buffer.toString();
  }
}
