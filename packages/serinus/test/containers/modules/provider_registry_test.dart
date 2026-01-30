import 'package:serinus/serinus.dart';
import 'package:serinus/src/containers/modules/provider_registry.dart';
import 'package:serinus/src/containers/modules/scope_manager.dart';
import 'package:test/test.dart';

class TestProvider extends Provider {}

class TestProviderTwo extends Provider {}

class TestProviderThree extends Provider {}

class GlobalTestProvider extends Provider {}

class TestModule extends Module {
  TestModule({
    super.providers,
    super.exports,
    super.isGlobal,
  });
}

void main() {
  group('ProviderRegistry', () {
    late ProviderRegistry registry;

    setUp(() {
      registry = ProviderRegistry();
    });

    test('should register a provider and track it', () {
      final provider = TestProvider();
      final scope = ModuleScope(
        token: InjectionToken('TestModule'),
        providers: {},
        exports: {},
        controllers: {},
        imports: {},
        module: TestModule(),
        importedBy: {},
      );

      final registered = registry.register(provider, scope);

      expect(registered, isTrue);
      expect(registry.isRegistered(TestProvider), isTrue);
      expect(registry.get<TestProvider>(), equals(provider));
    });

    test('should return false when registering duplicate provider', () {
      final provider = TestProvider();
      final scope = ModuleScope(
        token: InjectionToken('TestModule'),
        providers: {},
        exports: {},
        controllers: {},
        imports: {},
        module: TestModule(),
        importedBy: {},
      );

      registry.register(provider, scope);
      final duplicateResult = registry.register(TestProvider(), scope);

      expect(duplicateResult, isFalse);
    });

    test('should register provider under custom type', () {
      final provider = TestProviderTwo();
      final scope = ModuleScope(
        token: InjectionToken('TestModule'),
        providers: {},
        exports: {},
        controllers: {},
        imports: {},
        module: TestModule(),
        importedBy: {},
      );

      registry.register(provider, scope, asType: TestProvider);

      expect(registry.isRegistered(TestProvider), isTrue);
      expect(registry.isRegistered(TestProviderTwo), isFalse);
    });

    test('should track global providers', () {
      final provider = GlobalTestProvider();
      final scope = ModuleScope(
        token: InjectionToken('TestModule'),
        providers: {},
        exports: {},
        controllers: {},
        imports: {},
        module: TestModule(isGlobal: true),
        importedBy: {},
      );

      registry.register(provider, scope);

      expect(registry.globalProviders, contains(provider));
    });

    test('should get scope by provider type', () {
      final provider = TestProvider();
      final scope = ModuleScope(
        token: InjectionToken('TestModule'),
        providers: {},
        exports: {},
        controllers: {},
        imports: {},
        module: TestModule(),
        importedBy: {},
      );

      registry.register(provider, scope);

      expect(registry.getScopeByProvider(TestProvider), equals(scope));
    });

    test('should return all providers of a type', () {
      final provider1 = TestProvider();
      final provider2 = TestProviderTwo();
      final scope = ModuleScope(
        token: InjectionToken('TestModule'),
        providers: {},
        exports: {},
        controllers: {},
        imports: {},
        module: TestModule(),
        importedBy: {},
      );

      registry.register(provider1, scope);
      registry.register(provider2, scope);

      final allProviders = registry.getAll<Provider>();
      expect(allProviders.length, equals(2));
    });

    test('should process ClassProvider correctly', () {
      final classProvider = Provider.forClass<TestProvider>(
        useClass: TestProvider(),
      );

      final processed = registry.processCustomProviders([classProvider]);

      expect(processed.length, equals(1));
      expect(processed.first, isA<TestProvider>());
      expect(
        registry.getCustomToken(processed.first),
        equals(TestProvider),
      );
    });

    test('should identify missing dependencies', () {
      final scope = ModuleScope(
        token: InjectionToken('TestModule'),
        providers: {},
        exports: {},
        controllers: {},
        imports: {},
        module: TestModule(),
        importedBy: {},
      );

      registry.register(TestProvider(), scope);

      final missing = registry.getMissingDependencies([
        TestProvider,
        TestProviderTwo,
      ]);

      expect(missing, contains(TestProviderTwo));
      expect(missing, isNot(contains(TestProvider)));
    });

    test('should generate dependencies map', () {
      final provider1 = TestProvider();
      final provider2 = TestProviderTwo();

      final map = registry.generateDependenciesMap([provider1, provider2]);

      expect(map[TestProvider], equals(provider1));
      expect(map[TestProviderTwo], equals(provider2));
    });
  });
}
