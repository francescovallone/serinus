import 'package:mocktail/mocktail.dart';
import 'package:serinus/serinus.dart';
import 'package:serinus/src/containers/serinus_container.dart';
import 'package:test/test.dart';

import '../core/module_test.dart';
import '../mocks/controller_mock.dart';

class _MockAdapter extends Mock implements SerinusHttpAdapter {
  @override
  String get name => 'http';

  @override
  Future<void> close() {
    return Future.value();
  }
}

class TestModule extends Module {
  final List<Middleware>? middlewares;

  TestModule({
    String? token,
    List<Module>? imports,
    List<Controller>? controllers,
    List<Provider>? providers,
    this.middlewares,
    List<Type>? exports,
  }) : super(
         token: token ?? 'TestModule',
         imports: imports ?? [],
         controllers: controllers ?? [],
         providers: providers ?? [],
         exports: exports ?? [],
       );

  @override
  void configure(MiddlewareConsumer consumer) {
    consumer
        .apply([...(middlewares ?? [])])
        .forControllers(controllers.map((e) => e.runtimeType).toList());
  }
}

class TestProviderTwo extends Provider {
  final TestProvider dep;

  TestProviderTwo(this.dep);
}

class TestMiddleware extends Middleware {
  TestMiddleware() : super();

  @override
  Future<void> use(ExecutionContext context, NextFunction next) async {
    return next();
  }
}

abstract class BaseService extends Provider {
  String get value;
}

class BaseServiceImpl extends BaseService {
  @override
  String get value => 'impl';
}

class UsesCustomProviders extends Provider {
  final BaseService baseService;
  final String endpoint;

  UsesCustomProviders(this.baseService, this.endpoint);
}

class TestWsGateway extends WebSocketGateway {
  TestWsGateway() : super(path: '/ws');

  @override
  Future<void> onMessage(data, WebSocketContext context) async {}
}

void main() {
  group('GraphInspector', () {
    test(
      'should return a single node when a module with no dependencies is registered',
      () async {
        final config = ApplicationConfig(
          serverAdapter: SerinusHttpAdapter(
            host: 'localhost',
            port: 3000,
            poweredByHeader: 'Powered by Serinus',
          ),
        );
        final module = TestModule();
        final container = SerinusContainer(config, _MockAdapter());
        final inspector = container.inspector;
        final graph = inspector.graph;
        await container.modulesContainer.registerModules(module);
        inspector.inspectModules();
        expect(graph, isNotNull);
        expect(graph.nodes.length, 1);
        expect(graph.edges.length, 0);
      },
    );

    test(
      'should return multiple nodes and 0 edges when a module has providers and controllers but no dependencies',
      () async {
        final module = TestModule(
          controllers: [MockController()],
          providers: [TestProvider()],
        );
        final config = ApplicationConfig(
          serverAdapter: SerinusHttpAdapter(
            host: 'localhost',
            port: 3000,
            poweredByHeader: 'Powered by Serinus',
          ),
        );
        final container = SerinusContainer(config, _MockAdapter());
        final inspector = container.inspector;
        final graph = inspector.graph;
        await container.modulesContainer.registerModules(module);
        inspector.inspectModules();
        expect(graph, isNotNull);
        expect(graph.nodes.length, 3);
        expect(graph.edges.length, 0);
      },
    );

    test(
      'should return multiple nodes and edges when a module has dependencies',
      () async {
        final moduleA = TestModule(
          token: 'ModuleA',
          controllers: [MockController()],
          providers: [TestProvider()],
          exports: [TestProvider],
        );
        final moduleB = TestModule(
          token: 'ModuleB',
          imports: [moduleA],
          controllers: [MockController()],
          providers: [
            Provider.composed(
              (CompositionContext ctx) async =>
                  TestProviderTwo(ctx.use<TestProvider>()),
              inject: [TestProvider],
            ),
          ],
          middlewares: [TestMiddleware()],
        );
        final config = ApplicationConfig(
          serverAdapter: SerinusHttpAdapter(
            host: 'localhost',
            port: 3000,
            poweredByHeader: 'Powered by Serinus',
          ),
        );
        final container = SerinusContainer(config, _MockAdapter());
        final inspector = container.inspector;
        final graph = inspector.graph;
        await container.modulesContainer.registerModules(moduleB);
        await container.modulesContainer.finalize(moduleB);
        inspector.inspectModules();
        expect(graph, isNotNull);
        expect(graph.nodes.length, 5);
        expect(graph.edges.length, 2);
      },
    );

    test(
      'should return a representation of the graph with nodes and edges',
      () async {
        final moduleA = TestModule(
          token: 'ModuleA',
          controllers: [MockController()],
          providers: [],
        );
        final moduleB = TestModule(
          token: 'ModuleB',
          imports: [moduleA],
          controllers: [MockController()],
          providers: [TestProvider()],
          middlewares: [],
        );
        final config = ApplicationConfig(
          serverAdapter: SerinusHttpAdapter(
            host: 'localhost',
            port: 3000,
            poweredByHeader: 'Powered by Serinus',
          ),
        );
        final container = SerinusContainer(config, _MockAdapter());
        final inspector = container.inspector;
        final graph = inspector.graph;
        await container.modulesContainer.registerModules(moduleB);
        inspector.inspectModules();
        expect(graph, isNotNull);
      },
    );

    test(
      'should return a representation of the graph with nodes and edges',
      () async {
        final moduleA = TestModule(
          token: 'ModuleA',
          controllers: [MockController()],
          providers: [],
        );
        final moduleB = TestModule(
          token: 'ModuleB',
          imports: [moduleA],
          controllers: [MockController()],
          providers: [TestProvider()],
          middlewares: [],
        );
        final config = ApplicationConfig(
          serverAdapter: SerinusHttpAdapter(
            host: 'localhost',
            port: 3000,
            poweredByHeader: 'Powered by Serinus',
          ),
        );
        final container = SerinusContainer(config, _MockAdapter());
        final inspector = container.inspector;
        final graph = inspector.graph;
        await container.modulesContainer.registerModules(moduleB);
        inspector.inspectModules();
        expect(graph, isNotNull);
      },
    );

    test(
      'should include ClassProvider and ValueProvider nodes and edges',
      () async {
        final module = TestModule(
          providers: [
            Provider.forClass<BaseService>(useClass: BaseServiceImpl()),
            Provider.forValue<String>('https://api.example.com'),
            Provider.composed(
              (CompositionContext ctx) async => UsesCustomProviders(
                ctx.use<BaseService>(),
                ctx.use<String>(),
              ),
              inject: [BaseService, String],
            ),
          ],
        );

        final config = ApplicationConfig(
          serverAdapter: SerinusHttpAdapter(
            host: 'localhost',
            port: 3000,
            poweredByHeader: 'Powered by Serinus',
          ),
        );
        final container = SerinusContainer(config, _MockAdapter());
        final inspector = container.inspector;

        await container.modulesContainer.registerModules(module);
        await container.modulesContainer.finalize(module);
        inspector.inspectModules();

        final baseServiceNode =
            inspector.graph.nodes[InjectionToken.fromType(BaseService)];
        final valueNode = inspector
            .graph
            .nodes[InjectionToken.fromValueToken(ValueToken.of<String>())];

        expect(baseServiceNode, isNotNull);
        expect(valueNode, isNotNull);
        expect(
          (baseServiceNode as ClassNode).metadata.subTypes,
          contains('classProvider'),
        );
        expect(
          (valueNode as ClassNode).metadata.subTypes,
          contains('valueProvider'),
        );

        final consumerToken = InjectionToken.fromType(UsesCustomProviders);
        final classEdge = inspector.graph.edges.values.where(
          (edge) =>
              edge.source == consumerToken &&
              edge.target.name.contains('BaseService'),
        );
        final valueEdge = inspector.graph.edges.values.where(
          (edge) =>
              edge.source == consumerToken &&
              (edge.target ==
                      InjectionToken.fromValueToken(ValueToken.of<String>()) ||
                  edge.target == InjectionToken.fromType(String)),
        );
        expect(classEdge, isNotEmpty);
        expect(valueEdge, isNotEmpty);
      },
    );

    test(
      'should include controller, route and websocket gateway entrypoints',
      () async {
        final module = TestModule(
          controllers: [MockController('/test')],
          providers: [TestWsGateway()],
        );

        final config = ApplicationConfig(
          serverAdapter: SerinusHttpAdapter(
            host: 'localhost',
            port: 3000,
            poweredByHeader: 'Powered by Serinus',
          ),
        );
        final container = SerinusContainer(config, _MockAdapter());
        final inspector = container.inspector;

        await container.modulesContainer.registerModules(module);
        inspector.inspectModules();

        final entrypoints = inspector.graph.entrypoints.values.toList();
        expect(
          entrypoints.where(
            (entrypoint) => entrypoint.type.name == 'controller',
          ),
          isNotEmpty,
        );
        expect(
          entrypoints.where((entrypoint) => entrypoint.type.name == 'route'),
          isNotEmpty,
        );
        expect(
          entrypoints.where(
            (entrypoint) => entrypoint.type.name == 'websocketGateway',
          ),
          isNotEmpty,
        );
      },
    );
  });
}
