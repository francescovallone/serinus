import 'package:serinus/serinus.dart';
import 'package:serinus/src/containers/modules/scope_manager.dart';
import 'package:test/test.dart';

class TestProvider extends Provider {}

class TestProviderTwo extends Provider {}

class TestController extends Controller {
  TestController() : super('/test');
}

class TestModule extends Module {
  TestModule({
    super.providers,
    super.exports,
    super.controllers,
    super.imports,
    super.isGlobal,
  });
}

void main() {
  group('ScopeManager', () {
    late ScopeManager manager;

    setUp(() {
      manager = ScopeManager();
    });

    test('should register and retrieve scope', () {
      final token = InjectionToken('TestModule');
      final scope = ModuleScope(
        token: token,
        providers: {},
        exports: {},
        controllers: {},
        imports: {},
        module: TestModule(),
        importedBy: {},
      );

      manager.registerScope(scope);

      expect(manager.hasScope(token), isTrue);
      expect(manager.getScope(token), equals(scope));
    });

    test('should throw ArgumentError for non-existent scope', () {
      expect(
        () => manager.getScope(InjectionToken('NonExistent')),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('should return null for non-existent scope with getScopeOrNull', () {
      final result = manager.getScopeOrNull(InjectionToken('NonExistent'));
      expect(result, isNull);
    });

    test('should track controllers', () {
      final controller = TestController();
      final module = TestModule(controllers: [controller]);
      final scope = ModuleScope(
        token: InjectionToken('TestModule'),
        providers: {},
        exports: {},
        controllers: {controller},
        imports: {},
        module: module,
        importedBy: {},
      );

      manager.registerScope(scope);
      manager.addControllers(scope);

      expect(manager.controllers.length, equals(1));
      expect(manager.controllers.first.controller, equals(controller));
      expect(manager.controllers.first.module, equals(module));
    });

    test('should get module by token', () {
      final module = TestModule();
      final token = InjectionToken('TestModule');
      final scope = ModuleScope(
        token: token,
        providers: {},
        exports: {},
        controllers: {},
        imports: {},
        module: module,
        importedBy: {},
      );

      manager.registerScope(scope);

      expect(manager.getModuleByToken(token), equals(module));
    });

    test('should track entrypoint token and initialization state', () {
      expect(manager.isInitialized, isFalse);

      manager.entrypointToken = InjectionToken('EntryModule');

      expect(manager.isInitialized, isTrue);
    });

    test('should get parent modules', () {
      final parentModule = TestModule();
      final childModule = TestModule();
      // Use InjectionToken.fromModule to get the actual tokens
      final parentToken = InjectionToken.fromModule(parentModule);
      final childToken = InjectionToken.fromModule(childModule);

      final parentScope = ModuleScope(
        token: parentToken,
        providers: {},
        exports: {},
        controllers: {},
        imports: {childModule},
        module: parentModule,
        importedBy: {},
      );

      final childScope = ModuleScope(
        token: childToken,
        providers: {},
        exports: {},
        controllers: {},
        imports: {},
        module: childModule,
        importedBy: {parentToken},
      );

      manager.registerScope(parentScope);
      manager.registerScope(childScope);

      final parents = manager.getParents(childModule);
      expect(parents, contains(parentModule));
    });

    test('should refresh unified providers', () {
      final provider = TestProvider();
      final globalProvider = TestProviderTwo();
      final scope = ModuleScope(
        token: InjectionToken('TestModule'),
        providers: {provider},
        exports: {},
        controllers: {},
        imports: {},
        module: TestModule(),
        importedBy: {},
      );

      manager.registerScope(scope);
      manager.refreshUnifiedProviders([globalProvider]);

      expect(scope.unifiedProviders, contains(provider));
      expect(scope.unifiedProviders, contains(globalProvider));
    });

    test('should build composition context', () {
      final provider = TestProvider();

      final context = manager.buildCompositionContext([provider]);

      expect(context.use<TestProvider>(), equals(provider));
    });
  });

  group('ModuleScope', () {
    test('should extend with new providers', () {
      final scope = ModuleScope(
        token: InjectionToken('TestModule'),
        providers: {},
        exports: {},
        controllers: {},
        imports: {},
        module: TestModule(),
        importedBy: {},
      );

      final provider = TestProvider();
      scope.extend(providers: [provider]);

      expect(scope.providers, contains(provider));
    });

    test('should add to providers and unified providers', () {
      final scope = ModuleScope(
        token: InjectionToken('TestModule'),
        providers: {},
        exports: {},
        controllers: {},
        imports: {},
        module: TestModule(),
        importedBy: {},
      );

      final provider = TestProvider();
      scope.addToProviders(provider);

      expect(scope.providers, contains(provider));
      expect(scope.unifiedProviders, contains(provider));
    });

    test('should extend with dynamic module', () {
      final scope = ModuleScope(
        token: InjectionToken('TestModule'),
        providers: {},
        exports: {},
        controllers: {},
        imports: {},
        module: TestModule(),
        importedBy: {},
      );

      final provider = TestProvider();
      final dynamicModule = DynamicModule(providers: [provider]);

      scope.extendWithDynamicModule(dynamicModule);

      expect(scope.isDynamic, isTrue);
      expect(scope.providers, contains(provider));
    });
  });

  group('InstanceWrapper', () {
    test('should store metadata and dependencies', () {
      final token = InjectionToken('TestProvider');
      final wrapper = InstanceWrapper(
        name: token,
        metadata: ClassMetadataNode(
          type: InjectableType.provider,
          sourceModuleName: InjectionToken('TestModule'),
        ),
        host: InjectionToken('TestModule'),
        dependencies: [],
      );

      expect(wrapper.name, equals(token));
      expect(wrapper.metadata.type, equals(InjectableType.provider));
    });
  });
}
