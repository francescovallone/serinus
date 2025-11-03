import 'package:mocktail/mocktail.dart';
import 'package:serinus/serinus.dart';
import 'package:test/test.dart';

// internal composition context for tests

import '../mocks/injectables_mock.dart';
import '../mocks/module_mock.dart';

class _MockAdapter extends Mock implements HttpAdapter {
  @override
  String get name => 'http';
}

// Define a provider type that will be produced by a composed provider
class ProducedProvider extends Provider {
  ProducedProvider();

  String hello() => 'produced';
}

// Module produced by composed A: exports ProducedProvider produced by a ComposedProvider
class ProducedModuleA extends Module {
  ProducedModuleA()
    : super(
        controllers: [],
        providers: [
          Provider.composed<ProducedProvider>(
            (CompositionContext ctx) async => ProducedProvider(),
            inject: const [],
          ),
        ],
        exports: [ProducedProvider],
      );
}

// Top-level provider and module types used by the cycle test
class ProducedA extends Provider {
  ProducedA();
}

class ProducedB extends Provider {
  ProducedB();
}

// Module produced by composed B (just a placeholder)
class ProducedModuleB extends Module {
  ProducedModuleB() : super(controllers: [], providers: [], exports: []);
}

class ParentModule extends Module {
  ParentModule(List<Module> imports)
    : super(imports: imports, controllers: [], providers: [], exports: []);
}

class ValueProviderOne extends Provider {}

class ValueProviderTwo extends Provider {}

class ParameterizedModule extends Module {
  ParameterizedModule(Provider provider)
    : super(providers: [provider], exports: [provider.runtimeType]);
}

// Providers used in the multi-step chain
class P1 extends Provider {
  P1();
}

class P2 extends Provider {
  P2();
}

class P3 extends Provider {
  P3();
}

class P4 extends Provider {
  final P1 p1;
  final P2 p2;
  final P3 p3;
  P4(this.p1, this.p2, this.p3);
}

class ModuleA extends Module {
  ModuleA()
    : super(
        controllers: [],
        providers: [
          Provider.composed<P1>(
            (CompositionContext ctx) async => P1(),
            inject: [],
          ),
        ],
        exports: [P1],
      );
}

class ModuleB extends Module {
  ModuleB() : super(controllers: [], providers: [P2()], exports: [P2]);
}

class ModuleC extends Module {
  ModuleC() : super(controllers: [], providers: [P3()], exports: [P3]);
}

class ParentMultiStepModule extends Module {
  ParentMultiStepModule(List<Module> imports)
    : super(
        imports: imports,
        providers: [
          Provider.composed<P4>(
            (CompositionContext ctx) async =>
                P4(ctx.use<P1>(), ctx.use<P2>(), ctx.use<P3>()),
            inject: [P1, P2, P3],
          ),
        ],
      );
}

class WrongReturnProvider extends Provider {
  WrongReturnProvider();
}

class ModuleWithWrongComposed extends Module {
  ModuleWithWrongComposed()
    : super(
        controllers: [],
        providers: [
          // Declare ComposedProvider<TestProvider> but return TestProviderTwo at runtime
          // Use generic Provider to intentionally cause a runtime type mismatch
          Provider.composed<Provider>(
            (CompositionContext ctx) async => TestProviderTwo(),
            inject: [],
          ),
        ],
        exports: [],
      );
}

void main() {
  group('ComposedModule', () {
    test('composed init receives providers from imports and globals', () async {
      final container = ModulesContainer(
        ApplicationConfig(serverAdapter: _MockAdapter()),
      );

      // Prepare a global provider and an import that exports TestProviderTwo

      // Compose a module that depends on TestProviderTwo (exported by import)
      final composed = Module.composed<Module>((CompositionContext ctx) async {
        // return a Module instance that will register a composed provider
        return SimpleModuleWithProvider();
      }, inject: const []);

      await container.registerModules(
        SimpleMockModuleWithImports(imports: [composed]),
      );

      // After finalize, TestProviderThree (created by composed) should be available
      final got = container.get<TestProviderThree>();
      expect(got, isNotNull);
    });
  });
  group('ComposedModule (spec)', () {
    test('init receives CompositionContext and returns Module', () async {
      final composed = Module.composed<Module>((CompositionContext ctx) async {
        // return a Module instance from composed init
        return SimpleModuleWithProvider();
      }, inject: const []);

      // Cast to dynamic to access the init function
      final cm = composed as dynamic;

      // Build a minimal composition context with a provider map
      final ctx = CompositionContext({TestProvider: TestProvider()});

      final result = await cm.init(ctx);
      expect(result, isA<Module>());
    });

    test('ComposedModule cannot be used as application entrypoint', () async {
      final container = ModulesContainer(
        ApplicationConfig(serverAdapter: _MockAdapter()),
      );

      final composed = Module.composed<Module>(
        (CompositionContext ctx) async => SimpleModule(),
        inject: const [],
      );

      // Attempting to register a composed module as the top-level entrypoint
      // should be considered invalid by the framework. Expect an InitializationError.
      expect(
        () => container.registerModules(composed),
        throwsA(isA<InitializationError>()),
      );
    });
  });
  group('ComposedModule chain', () {
    test(
      'provider produced by ComposedModule A is available to ComposedModule B',
      () async {
        final composedA = Module.composed<Module>((
          CompositionContext ctx,
        ) async {
          return ProducedModuleA();
        }, inject: const []);

        final composedB = Module.composed<Module>(
          (CompositionContext ctx) async {
            // Try to resolve ProducedProvider from context — should be present when this init runs
            final ProducedProvider p = ctx.use<ProducedProvider>();
            expect(p, isNotNull);
            expect(p.hello(), equals('produced'));
            return ProducedModuleB();
          },
          // B depends on the provider produced by A
          inject: const [ProducedProvider],
        );

        final parent = ParentModule([composedA, composedB]);

        final container = ModulesContainer(
          ApplicationConfig(serverAdapter: _MockAdapter()),
        );
        await container.registerModules(parent);
        await container.finalize(parent);

        // After finalize, the produced provider should be registered in the container
        final produced = container.get<ProducedProvider>();
        expect(produced, isNotNull);
        expect(produced?.hello(), equals('produced'));
      },
    );
  });
  group('ComposedModule behavior', () {
    test('ComposedModule.init returns a Module when invoked', () async {
      // build a composed module which returns a Module instance
      final composed = Module.composed<Module>((CompositionContext ctx) async {
        // the init returns a Module instance
        return SimpleModuleWithProvider();
      }, inject: const []);

      // prepare a simple composition context with a provider instance
      final ctx = CompositionContext({TestProviderTwo: TestProviderTwo()});

      final result = await (composed as dynamic).init(ctx);
      expect(result, isA<Module>());
    });

    test('ComposedModule cannot be used as entrypoint', () async {
      final container = ModulesContainer(
        ApplicationConfig(serverAdapter: _MockAdapter()),
      );

      final composed = Module.composed<Module>(
        (CompositionContext ctx) async => SimpleModule(),
        inject: const [],
      );

      // Composed modules should not be allowed as application entrypoints.
      // Framework is expected to throw InitializationError when attempting
      // to register a composed module as the top-level entrypoint.
      expect(
        () => container.registerModules(composed),
        throwsA(isA<InitializationError>()),
      );
    });
  });
  group('ComposedModule cycle detection', () {
    test(
      'finalize throws InitializationError on cyclic composed modules',
      () async {
        final composedA = Module.composed<Module>((
          CompositionContext ctx,
        ) async {
          return ProducedModuleA();
        }, inject: [ProducedB]);

        final composedB = Module.composed<Module>((
          CompositionContext ctx,
        ) async {
          return ProducedModuleB();
        }, inject: [ProducedA]);

        // Create a concrete parent module importing both composed modules
        final parent = ParentModule([composedA, composedB]);

        final container = ModulesContainer(
          ApplicationConfig(serverAdapter: _MockAdapter()),
        );
        await container.registerModules(parent);

        // finalize should detect unresolved composed modules cycle and throw
        expect(
          () => container.finalize(parent),
          throwsA(isA<InitializationError>()),
        );
      },
    );
  });
  group('ComposedModule multi-step chain', () {
    test(
      'A -> B -> C chain resolves providers across composed modules',
      () async {
        final composedA = Module.composed<Module>(
          (ctx) async => ModuleA(),
          inject: [],
        );
        final composedB = Module.composed<Module>(
          (ctx) async => ModuleB(),
          inject: [P1],
        );
        final composedC = Module.composed<Module>(
          (ctx) async => ModuleC(),
          inject: [P2],
        );

        final parent = ParentMultiStepModule([composedA, composedB, composedC]);
        final container = ModulesContainer(
          ApplicationConfig(serverAdapter: _MockAdapter()),
        );
        await container.registerModules(parent);
        await container.finalize(parent);

        final p1 = container.get<P1>();
        final p2 = container.get<P2>();
        final p3 = container.get<P3>();
        expect(p1, isNotNull);
        expect(p2, isNotNull);
        expect(p3, isNotNull);

        // ensure metadata marks composed providers as composed
        final scopeForP3 = container.getScopeByProvider(P3);
        final token = InjectionToken.fromType(P3);
        final meta = scopeForP3.instanceMetadata[token];
        expect(meta, isNotNull);
        final p4 = container.get<P4>();
        expect(p4, isNotNull);
        expect(identical(p4!.p1, p1), isTrue);
        expect(identical(p4.p2, p2), isTrue);
        expect(identical(p4.p3, p3), isTrue);
      },
    );
  });
  group('ComposedProvider wrong runtime type', () {
    test(
      'finalize throws InitializationError when composed provider returns wrong type',
      () async {
        final composed = Module.composed<Module>(
          (ctx) async => ModuleWithWrongComposed(),
          inject: [],
        );
        final parent = ParentModule([composed]);
        final container = ModulesContainer(
          ApplicationConfig(serverAdapter: _MockAdapter()),
        );
        await container.registerModules(parent);
        expect(
          () => container.finalize(parent),
          throwsA(isA<InitializationError>()),
        );
      },
    );
  });
}
