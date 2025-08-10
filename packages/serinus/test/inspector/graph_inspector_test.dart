import 'dart:convert';

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
  TestModule({
    String? token,
    List<Module>? imports,
    List<Controller>? controllers,
    List<Provider>? providers,
    List<Middleware>? middlewares,
    List<Type>? exports,
  }) : super(
          token: token ?? 'TestModule',
          imports: imports ?? [],
          controllers: controllers ?? [],
          providers: providers ?? [],
          middlewares: middlewares ?? [],
          exports: exports ?? [],
        );
}

class TestProviderTwo extends Provider {

  final TestProvider dep;

  TestProviderTwo(this.dep);
}

class TestMiddleware extends Middleware {
  TestMiddleware() : super(routes: ['*']);

  @override
  Future<void> use(RequestContext context, NextFunction next) async {
    return next();
  }
}

void main() {
  group(
    'GraphInspector',
    () {
      test(
        'should return a single node when a module with no dependencies is registered',
        () async {
          final config = ApplicationConfig(
            serverAdapter: SerinusHttpAdapter(
              host: 'localhost',
              port: 3000,
              poweredByHeader: 'Powered by Serinus',
            )
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
              controllers: [MockController()], providers: [TestProvider()]);
          final config = ApplicationConfig(
            serverAdapter: SerinusHttpAdapter(
              host: 'localhost',
              port: 3000,
              poweredByHeader: 'Powered by Serinus',
            )
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
              exports: [TestProvider]);
          final moduleB = TestModule(token: 'ModuleB', imports: [
            moduleA
          ], controllers: [
            MockController()
          ], providers: [
            Provider.composed(
              (TestProvider provider) => TestProviderTwo(provider),
              inject: [TestProvider],
              type: TestProviderTwo,
            )
          ], middlewares: [
            TestMiddleware()
          ]);
          final config = ApplicationConfig(
            serverAdapter: SerinusHttpAdapter(
              host: 'localhost',
              port: 3000,
              poweredByHeader: 'Powered by Serinus',
            )
          );
          final container = SerinusContainer(config, _MockAdapter());
          final inspector = container.inspector;
          final graph = inspector.graph;
          await container.modulesContainer.registerModules(moduleB);
          await container.modulesContainer.finalize(moduleB);
          inspector.inspectModules();
          expect(graph, isNotNull);
          expect(graph.nodes.length, 6);
          expect(graph.edges.length, 2);
        },
      );

      test(
        'should return a representation of the graph with nodes and edges',
        () async {
          final moduleA = TestModule(
              token: 'ModuleA', controllers: [MockController()], providers: []);
          final moduleB = TestModule(
              token: 'ModuleB',
              imports: [moduleA],
              controllers: [MockController()],
              providers: [TestProvider()],
              middlewares: []);
          final config = ApplicationConfig(
            serverAdapter: SerinusHttpAdapter(
              host: 'localhost',
              port: 3000,
              poweredByHeader: 'Powered by Serinus',
            )
          );
          final container = SerinusContainer(config, _MockAdapter());
          final inspector = container.inspector;
          final graph = inspector.graph;
          await container.modulesContainer.registerModules(moduleB);
          inspector.inspectModules();
          expect(graph, isNotNull);
          expect(jsonEncode(inspector.toJson()),
              '{"nodes":[{"id":"ModuleB","label":"ModuleB","metadata":{"name":"module","global":false}},{"id":"TestProvider","label":"TestProvider","parent":"ModuleB","metadata":{"type":"provider","sourceModuleName":"ModuleB","initTime":0,"exported":false,"composed":false}},{"id":"MockController","label":"MockController","parent":"ModuleB","metadata":{"type":"controller","sourceModuleName":"ModuleB","initTime":0}},{"id":"ModuleA","label":"ModuleA","metadata":{"name":"module","global":false}}],"edges":[{"id":"ModuleB-ModuleA","source":"ModuleB","target":"ModuleA","metadata":{"sourceModuleName":"ModuleB","targetModuleName":"ModuleA","type":"module_to_module"}}]}');
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
              middlewares: []);
          final config = ApplicationConfig(
            serverAdapter: SerinusHttpAdapter(
              host: 'localhost',
              port: 3000,
              poweredByHeader: 'Powered by Serinus',
            )
          );
          final container = SerinusContainer(config, _MockAdapter());
          final inspector = container.inspector;
          final graph = inspector.graph;
          await container.modulesContainer.registerModules(moduleB);
          inspector.inspectModules();
          expect(graph, isNotNull);
          expect(jsonEncode(inspector.toJson()),
              '{"nodes":[{"id":"ModuleB","label":"ModuleB","metadata":{"name":"module","global":false}},{"id":"TestProvider","label":"TestProvider","parent":"ModuleB","metadata":{"type":"provider","sourceModuleName":"ModuleB","initTime":0,"exported":false,"composed":false}},{"id":"MockController","label":"MockController","parent":"ModuleB","metadata":{"type":"controller","sourceModuleName":"ModuleB","initTime":0}},{"id":"ModuleA","label":"ModuleA","metadata":{"name":"module","global":false}}],"edges":[{"id":"ModuleB-ModuleA","source":"ModuleB","target":"ModuleA","metadata":{"sourceModuleName":"ModuleB","targetModuleName":"ModuleA","type":"module_to_module"}}]}');
        },
      );
    },
  );
}
