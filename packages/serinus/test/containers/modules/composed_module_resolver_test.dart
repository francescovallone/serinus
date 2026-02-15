import 'package:serinus/serinus.dart';
import 'package:serinus/src/containers/modules/composed_module_resolver.dart';
import 'package:serinus/src/containers/modules/scope_manager.dart';
import 'package:test/test.dart';

class TestProvider extends Provider {}

class TestProviderTwo extends Provider {}

class TestModule extends Module {
  TestModule({super.providers, super.exports, super.isGlobal});
}

class ProducedModule extends Module {
  ProducedModule()
    : super(providers: [TestProvider()], exports: [TestProvider]);
}

ComposedModule<T> createComposedModule<T extends Module>(
  Future<T> Function(CompositionContext context) init, {
  required List<Type> inject,
}) {
  return Module.composed<T>(init, inject: inject) as ComposedModule<T>;
}

void main() {
  group('ComposedModuleResolver', () {
    late ScopeManager scopeManager;
    late ComposedModuleResolver resolver;
    late List<Module> registeredModules;

    setUp(() {
      scopeManager = ScopeManager();
      registeredModules = [];

      Future<void> mockRegisterModule(
        Module module, {
        bool internal = false,
        int depth = 0,
      }) async {
        registeredModules.add(module);
        final token = InjectionToken.fromModule(module);
        final scope = ModuleScope(
          token: token,
          providers: {...module.providers},
          exports: {...module.exports},
          controllers: {...module.controllers},
          imports: {...module.imports},
          module: module,
          importedBy: {},
        );
        scopeManager.registerScope(scope);
      }

      resolver = ComposedModuleResolver(scopeManager, mockRegisterModule);
    });

    test('should add and retrieve pending composed modules', () {
      final parentToken = InjectionToken('ParentModule');
      final parentModule = TestModule();
      final composedModule = createComposedModule<ProducedModule>(
        (ctx) async => ProducedModule(),
        inject: [],
      );

      resolver.addPending(
        parentToken,
        ComposedModuleEntry(
          module: composedModule,
          parentModule: parentModule,
          parentToken: parentToken,
        ),
      );

      expect(resolver.hasPending, isTrue);
      expect(resolver.getPendingModules().length, equals(1));
    });

    test('should calculate missing dependencies', () {
      final missing = resolver.getMissingDependencies(
        [TestProvider, TestProviderTwo],
        [TestProvider()],
      );

      expect(missing, contains(TestProviderTwo));
      expect(missing, isNot(contains(TestProvider)));
    });

    test('should initialize composed module without dependencies', () async {
      final parentToken = InjectionToken('ParentModule');
      final parentModule = TestModule();
      final composedModule = createComposedModule<ProducedModule>(
        (ctx) async => ProducedModule(),
        inject: [],
      );

      final parentScope = ModuleScope(
        token: parentToken,
        providers: {},
        exports: {},
        controllers: {},
        imports: {},
        module: parentModule,
        importedBy: {},
      );
      scopeManager.registerScope(parentScope);
      scopeManager.refreshUnifiedProviders([]);

      resolver.addPending(
        parentToken,
        ComposedModuleEntry(
          module: composedModule,
          parentModule: parentModule,
          parentToken: parentToken,
        ),
      );

      final progress = await resolver.initializeComposedModules();

      expect(progress, isTrue);
      expect(registeredModules.length, equals(1));
      expect(registeredModules.first, isA<ProducedModule>());
    });

    test('should defer initialization when dependencies are missing', () async {
      final parentToken = InjectionToken('ParentModule');
      final parentModule = TestModule();
      final composedModule = createComposedModule<ProducedModule>(
        (ctx) async => ProducedModule(),
        inject: [TestProvider],
      );

      final parentScope = ModuleScope(
        token: parentToken,
        providers: {},
        exports: {},
        controllers: {},
        imports: {},
        module: parentModule,
        importedBy: {},
      );
      scopeManager.registerScope(parentScope);
      scopeManager.refreshUnifiedProviders([]);

      resolver.addPending(
        parentToken,
        ComposedModuleEntry(
          module: composedModule,
          parentModule: parentModule,
          parentToken: parentToken,
        ),
      );

      final progress = await resolver.initializeComposedModules();

      expect(progress, isFalse);
      expect(registeredModules, isEmpty);
    });

    test('should initialize when dependency becomes available', () async {
      final parentToken = InjectionToken('ParentModule');
      final parentModule = TestModule();
      final composedModule = createComposedModule<ProducedModule>(
        (ctx) async => ProducedModule(),
        inject: [TestProvider],
      );

      final dependency = TestProvider();
      final parentScope = ModuleScope(
        token: parentToken,
        providers: {dependency},
        exports: {},
        controllers: {},
        imports: {},
        module: parentModule,
        importedBy: {},
      );
      scopeManager.registerScope(parentScope);
      scopeManager.refreshUnifiedProviders([]);

      resolver.addPending(
        parentToken,
        ComposedModuleEntry(
          module: composedModule,
          parentModule: parentModule,
          parentToken: parentToken,
        ),
      );

      final progress = await resolver.initializeComposedModules();

      expect(progress, isTrue);
      expect(registeredModules.length, equals(1));
    });

    test('should cleanup resolved modules', () async {
      final parentToken = InjectionToken('ParentModule');
      final parentModule = TestModule();
      final composedModule = createComposedModule<ProducedModule>(
        (ctx) async => ProducedModule(),
        inject: [],
      );

      final parentScope = ModuleScope(
        token: parentToken,
        providers: {},
        exports: {},
        controllers: {},
        imports: {},
        module: parentModule,
        importedBy: {},
      );
      scopeManager.registerScope(parentScope);
      scopeManager.refreshUnifiedProviders([]);

      resolver.addPending(
        parentToken,
        ComposedModuleEntry(
          module: composedModule,
          parentModule: parentModule,
          parentToken: parentToken,
        ),
      );

      await resolver.initializeComposedModules();

      expect(resolver.getPendingModules(), isEmpty);
    });

    test('should create error message for unresolved modules', () {
      final parentToken = InjectionToken('ParentModule');
      final parentModule = TestModule();
      final composedModule = createComposedModule<ProducedModule>(
        (ctx) async => ProducedModule(),
        inject: [TestProvider],
      );

      final parentScope = ModuleScope(
        token: parentToken,
        providers: {},
        exports: {},
        controllers: {},
        imports: {},
        module: parentModule,
        importedBy: {},
      );
      scopeManager.registerScope(parentScope);

      resolver.addPending(
        parentToken,
        ComposedModuleEntry(
          module: composedModule,
          parentModule: parentModule,
          parentToken: parentToken,
        ),
      );

      final error = resolver.createUnresolvedError();

      expect(error, contains('Cannot resolve composed modules'));
      expect(error, contains('TestProvider'));
    });
  });

  group('ComposedModuleEntry', () {
    test('should track initialization state', () {
      final entry = ComposedModuleEntry(
        module: createComposedModule<TestModule>(
          (ctx) async => TestModule(),
          inject: [],
        ),
        parentModule: TestModule(),
        parentToken: InjectionToken('Parent'),
      );

      expect(entry.isInitialized, isFalse);
      entry.isInitialized = true;
      expect(entry.isInitialized, isTrue);
    });

    test('should track missing dependencies', () {
      final entry = ComposedModuleEntry(
        module: createComposedModule<TestModule>(
          (ctx) async => TestModule(),
          inject: [TestProvider],
        ),
        parentModule: TestModule(),
        parentToken: InjectionToken('Parent'),
      );

      entry.missingDependencies.add(TestProvider);

      expect(entry.missingDependencies, contains(TestProvider));
    });
  });
}
