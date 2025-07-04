
import '../core/application_config.dart';
import '../inspector/inspector.dart';
import 'module_container.dart';
import 'router.dart';

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

  /// The [router] is the router of the application.
  /// It is used to define the routes of the application and to handle the requests.
  final Router router = Router();

  /// The [SerinusContainer] constructor is used to create a new instance of the [SerinusContainer] class.
  /// It initializes the [modulesContainer] and the [inspector].
  SerinusContainer(this.config) {
    modulesContainer = ModulesContainer(config);
    inspector = GraphInspector(SerializedGraph(), modulesContainer);
  }
  

}