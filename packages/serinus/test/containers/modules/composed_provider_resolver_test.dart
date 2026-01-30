import 'package:serinus/serinus.dart';
import 'package:serinus/src/containers/modules/composed_provider_resolver.dart';
import 'package:serinus/src/containers/modules/provider_registry.dart';
import 'package:serinus/src/containers/modules/scope_manager.dart';
import 'package:test/test.dart';

class TestProvider extends Provider {}

class TestProviderTwo extends Provider {}

class DependentProvider extends Provider {
  final TestProvider dependency;
  DependentProvider(this.dependency);
}

class TestModule extends Module {
  TestModule({
    super.providers,
    super.exports,
    super.isGlobal,
  });
}

void main() {
  group('ComposedProviderResolver', () {
    late ProviderRegistry providerRegistry;
    late ScopeManager scopeManager;
    late ComposedProviderResolver resolver;

    setUp(() {
      providerRegistry = ProviderRegistry();
      scopeManager = ScopeManager();
      resolver = ComposedProviderResolver(providerRegistry, scopeManager);
    });

    test('should add and retrieve pending composed providers', () {
      final token = InjectionToken('TestModule');
      final composedProvider = Provider.composed<TestProvider>(
        (ctx) async => TestProvider(),
        inject: [],
      );

      resolver.addPending(token, [composedProvider]);

      final pending = resolver.getPending(token);
      expect(pending, isNotNull);
      expect(pending!.length, equals(1));
    });

    test('should initialize composed provider without dependencies', () async {
      final token = InjectionToken('TestModule');
      final module = TestModule();
      final composedProvider = Provider.composed<TestProvider>(
        (ctx) async => TestProvider(),
        inject: [],
      );
      final scope = ModuleScope(
        token: token,
        providers: {composedProvider},
        exports: {},
        controllers: {},
        imports: {},
        module: module,
        importedBy: {},
      );

      scopeManager.registerScope(scope);
      scopeManager.refreshUnifiedProviders([]);
      resolver.addPending(token, [composedProvider]);

      final progress = await resolver.initializeComposedProviders();

      expect(progress, isTrue);
      expect(providerRegistry.isRegistered(TestProvider), isTrue);
    });

    test('should defer initialization when dependencies are missing', () async {
      final token = InjectionToken('TestModule');
      final module = TestModule();
      final composedProvider = Provider.composed<DependentProvider>(
        (ctx) async => DependentProvider(ctx.use<TestProvider>()),
        inject: [TestProvider],
      );
      final scope = ModuleScope(
        token: token,
        providers: {composedProvider},
        exports: {},
        controllers: {},
        imports: {},
        module: module,
        importedBy: {},
      );

      scopeManager.registerScope(scope);
      scopeManager.refreshUnifiedProviders([]);
      resolver.addPending(token, [composedProvider]);

      final progress = await resolver.initializeComposedProviders();

      // No progress because dependency is missing
      expect(progress, isFalse);
      expect(providerRegistry.isRegistered(DependentProvider), isFalse);
    });

    test('should resolve provider when dependency becomes available', () async {
      final token = InjectionToken('TestModule');
      final module = TestModule();
      final testProvider = TestProvider();
      final composedProvider = Provider.composed<DependentProvider>(
        (ctx) async => DependentProvider(ctx.use<TestProvider>()),
        inject: [TestProvider],
      );
      final scope = ModuleScope(
        token: token,
        providers: {testProvider, composedProvider},
        exports: {},
        controllers: {},
        imports: {},
        module: module,
        importedBy: {},
      );

      scopeManager.registerScope(scope);
      providerRegistry.register(testProvider, scope);
      scopeManager.refreshUnifiedProviders([]);
      resolver.addPending(token, [composedProvider]);

      // Initialize should now work since testProvider is in unifiedProviders
      final progress = await resolver.initializeComposedProviders();

      expect(progress, isTrue);
      expect(providerRegistry.isRegistered(DependentProvider), isTrue);
    });

    test('should attach existing provider to scope instead of duplicating', () async {
      final token1 = InjectionToken('TestModule1');
      final token2 = InjectionToken('TestModule2');
      final module1 = TestModule();
      final module2 = TestModule();
      
      final composedProvider1 = Provider.composed<TestProvider>(
        (ctx) async => TestProvider(),
        inject: [],
      );
      final composedProvider2 = Provider.composed<TestProvider>(
        (ctx) async => TestProvider(),
        inject: [],
      );

      final scope1 = ModuleScope(
        token: token1,
        providers: {composedProvider1},
        exports: {},
        controllers: {},
        imports: {},
        module: module1,
        importedBy: {},
      );
      final scope2 = ModuleScope(
        token: token2,
        providers: {composedProvider2},
        exports: {},
        controllers: {},
        imports: {},
        module: module2,
        importedBy: {},
      );

      scopeManager.registerScope(scope1);
      scopeManager.registerScope(scope2);
      resolver.addPending(token1, [composedProvider1]);
      resolver.addPending(token2, [composedProvider2]);

      scopeManager.refreshUnifiedProviders([]);
      await resolver.initializeComposedProviders();

      // Only one TestProvider should be registered
      expect(providerRegistry.isRegistered(TestProvider), isTrue);
      expect(providerRegistry.allProviders.where((p) => p is TestProvider).length, equals(1));
    });
  });
}
