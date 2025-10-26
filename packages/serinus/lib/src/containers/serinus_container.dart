import '../adapters/http_adapter.dart';
import '../core/core.dart';
import '../injector/internal_core_module.dart';
import '../inspector/inspector.dart';
import '../mixins/provider_mixins.dart';
import '../routes/routes_resolver.dart';
import 'modules_container.dart';

/// The [SerinusContainer] is the main container of the Serinus Framework.
class SerinusContainer {
  /// The [modulesContainer] behaves as a DI Container for the Serinus Framework.
  /// It contains all the modules and their dependencies and it is responsible for
  /// resolving the dependencies and providing them to the application.
  late final ModulesContainer modulesContainer;

  /// The [inspector] is used to inspect the graph of the application.
  /// It is used to debug the application and to inspect the dependencies.
  late final GraphInspector inspector;

  /// The [config] is the application configuration.
  /// It contains the application settings and it is used to configure the application.
  final ApplicationConfig config;

  /// The [SerinusContainer] constructor is used to create a new instance of the [SerinusContainer] class.
  /// It initializes the [modulesContainer] and the [inspector].
  SerinusContainer(this.config, this.applicationRef) {
    modulesContainer = ModulesContainer(config);
    config.modulesContainer = modulesContainer;
    inspector = GraphInspector(SerializedGraph(), modulesContainer);
  }

  /// The [isInitialized] property is used to check if the modules container is initialized.
  bool get isInitialized => modulesContainer.isInitialized;

  /// The [applicationRef] is the reference to the application default http adapter.
  final HttpAdapter applicationRef;

  /// The [emitHook] method is used to emit a hook to the modules container.
  /// It takes a generic type [T] that extends [Provider] and emits the hook
  Future<void> emitHook<T extends Provider>() async {
    final providers = modulesContainer.getAll<T>();
    if (T == OnApplicationReady) {
      for (final provider in providers) {
        await (provider as OnApplicationReady).onApplicationReady();
      }
    } else if (T == OnApplicationShutdown) {
      for (final provider in providers) {
        await (provider as OnApplicationShutdown).onApplicationShutdown();
      }
    } else if (T == OnApplicationBootstrap) {
      for (final provider in providers) {
        await (provider as OnApplicationBootstrap).onApplicationBootstrap();
      }
    } else if (T == OnApplicationInit) {
      for (final provider in providers) {
        await (provider as OnApplicationInit).onApplicationInit();
      }
    }
  }

  /// The [init] method is used to initialize the modules container.
  /// It takes a [Module] as the entrypoint of the application and an optional
  /// [RoutesResolver] to resolve the routes of the application.
  /// It registers the modules and finalizes the container.
  Future<void> init(Module entrypoint, RoutesResolver? routesResolver) async {
    if (!modulesContainer.isInitialized) {
      await modulesContainer.registerModules(
        InternalCoreModule(inspector, config.microservices.isNotEmpty),
        internal: true,
      );
      await modulesContainer.registerModules(entrypoint);
    }
    routesResolver?.resolve();
    await modulesContainer.finalize(entrypoint);
    inspector.inspectModules(modulesContainer.scopes);
    await emitHook<OnApplicationBootstrap>();
  }
}
