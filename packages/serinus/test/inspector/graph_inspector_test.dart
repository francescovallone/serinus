import 'dart:convert';

import 'package:serinus/serinus.dart';
import 'package:test/test.dart';

import '../core/module_test.dart';
import '../mocks/controller_mock.dart';

class TestModule extends Module {

  TestModule({
    String? token,
    List<Module>? imports,
    List<Controller>? controllers,
    List<Provider>? providers,
    List<Middleware>? middlewares,
  }) : super(
    token: token ?? 'TestModule',
    imports: imports ?? [],
    controllers: controllers ?? [],
    providers: providers ?? [],
    middlewares: middlewares ?? [],
  );
}

void main() {

  group(
    'GraphInspector',
    () {
      test(
        'should return a single node when a module with no dependencies is registered',
        () async {
          final module = TestModule();
          final container = ModulesContainer(config);
          final inspector = container.inspector;
          final graph = inspector.graph;
          await container.registerModules(module);
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
            providers: [TestProvider()]
          );
          final container = ModulesContainer(config);
          final inspector = container.inspector;
          final graph = inspector.graph;
          await container.registerModules(module);
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
            providers: []
          );
          final moduleB = TestModule(
            token: 'ModuleB',
            imports: [moduleA],
            controllers: [MockController()],
            providers: [TestProvider()]
          );
          final container = ModulesContainer(config);
          final inspector = container.inspector;
          final graph = inspector.graph;
          await container.registerModules(moduleB);
          inspector.inspectModules();
          expect(graph, isNotNull);
          expect(graph.nodes.length, 4);
          expect(graph.edges.length, 1);
        },
      );

      test(
        'should return a representation of the graph with nodes and edges',
        () async {
          final moduleA = TestModule(
            token: 'ModuleA',
            controllers: [MockController()],
            providers: []
          );
          final moduleB = TestModule(
            token: 'ModuleB',
            imports: [moduleA],
            controllers: [MockController()],
            providers: [TestProvider()]
          );
          final container = ModulesContainer(config);
          final inspector = container.inspector;
          final graph = inspector.graph;
          await container.registerModules(moduleB);
          inspector.inspectModules();
          expect(graph, isNotNull);
          expect(jsonEncode(inspector.toJson()), '{"nodes":[{"id":"ModuleB","label":"ModuleB","metadata":{"name":"module"}},{"id":"TestProvider","label":"TestProvider","parent":"ModuleB","metadata":{"type":"provider","sourceModuleName":"ModuleB","initTime":0,"exported":false,"composed":false,"global":false}},{"id":"MockController","label":"MockController","parent":"ModuleB","metadata":{"type":"controller","sourceModuleName":"ModuleB","initTime":0}},{"id":"ModuleA","label":"ModuleA","metadata":{"name":"module"}}],"edges":[{"id":"ModuleB-ModuleA","source":"ModuleB","target":"ModuleA","metadata":{"sourceModuleName":"ModuleB","targetModuleName":"ModuleA","type":"module_to_module"}}]}');
        },
      );
    },
  );

}