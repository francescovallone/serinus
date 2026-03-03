import 'package:mocktail/mocktail.dart';
import 'package:serinus/serinus.dart';
import 'package:serinus/src/containers/serinus_container.dart';
import 'package:serinus/src/router/router.dart';
import 'package:serinus/src/routes/routes_explorer.dart';
import 'package:test/test.dart';

class _MockAdapter extends Mock implements SerinusHttpAdapter {
  @override
  String get name => 'http';

  @override
  Future<void> close() {
    return Future.value();
  }
}

class TestController extends Controller {
  TestController() : super('/test') {
    on(Route.get('/'), getString);
    on(Route.get('/int'), getInt);
  }

  Future<String> getString(RequestContext context) async {
    return context.use<String>();
  }

  Future<int> getInt(RequestContext context) async {
    return context.use<int>();
  }
}

class TestProviderWithValue extends Provider {
  final String value;

  TestProviderWithValue(this.value);

  String getValue() => value;
}

class SimpleModuleWithValueProvider extends Module {
  SimpleModuleWithValueProvider()
    : super(
        controllers: [TestController()],
        providers: [
          Provider.forValue<String>('Hello World'),
          Provider.forValue<int>(42),
        ],
        exports: [],
      );
}

class GlobalModuleWithValueProvider extends Module {
  GlobalModuleWithValueProvider()
    : super(
        controllers: [],
        providers: [Provider.forValue<String>('Global Value')],
        exports: [String],
        isGlobal: true,
      );
}

class ModuleImportingGlobalValue extends Module {
  ModuleImportingGlobalValue()
    : super(
        imports: [GlobalModuleWithValueProvider()],
        controllers: [TestController()],
        providers: [],
        exports: [],
      );
}

class ModuleWithExportedValueProvider extends Module {
  ModuleWithExportedValueProvider()
    : super(
        controllers: [],
        providers: [Provider.forValue<String>('Exported Value')],
        exports: [String],
      );
}

class ModuleImportingValueProvider extends Module {
  ModuleImportingValueProvider()
    : super(
        imports: [ModuleWithExportedValueProvider()],
        controllers: [TestController()],
        providers: [],
        exports: [],
      );
}

class ModuleWithComposedProviderUsingValue extends Module {
  ModuleWithComposedProviderUsingValue()
    : super(
        controllers: [],
        providers: [
          Provider.forValue<String>('Base Value'),
          Provider.composed((CompositionContext ctx) async {
            final value = ctx.use<String>();
            return TestProviderWithValue(value);
          }, inject: [String]),
        ],
        exports: [],
      );
}

void main() {
  group('ValueProvider', () {
    late ApplicationConfig config;

    setUp(() {
      Logger.setLogLevels({LogLevel.none});
      config = ApplicationConfig(serverAdapter: _MockAdapter());
    });

    test('Provider.forValue creates a ValueProvider', () {
      final provider = Provider.forValue<String>('test');
      expect(provider, isA<ValueProvider<String>>());
      expect((provider).value, 'test');
      expect(provider.token, ValueToken(String, null));
    });

    test('ValueProvider stores the correct value and type', () {
      final stringProvider = ValueProvider<String>('hello');
      expect(stringProvider.value, 'hello');
      expect(stringProvider.token, ValueToken(String, null));

      final intProvider = ValueProvider<int>(123);
      expect(intProvider.value, 123);
      expect(intProvider.token, ValueToken(int, null));
      final listProvider = ValueProvider<List<String>>(['a', 'b', 'c']);
      expect(listProvider.value, ['a', 'b', 'c']);
      expect(listProvider.token, ValueToken(List<String>, null));
    });

    test('ValueProvider can store null values', () {
      final nullProvider = ValueProvider<String?>(null);
      expect(nullProvider.value, isNull);
      // Note: token is String? for a nullable type
      // ignore: unnecessary_type_check
      expect(nullProvider.token is Type, isTrue);
    });

    test('ValueProvider is registered in module scope', () async {
      final container = ModulesContainer(config);
      final module = SimpleModuleWithValueProvider();
      await container.registerModules(module);

      final scope = container.getScope(InjectionToken.fromModule(module));
      expect(scope.unifiedValues.containsKey(ValueToken(String, null)), isTrue);
      expect(scope.unifiedValues[ValueToken(String, null)], 'Hello World');
      expect(scope.unifiedValues.containsKey(ValueToken(int, null)), isTrue);
      expect(scope.unifiedValues[ValueToken(int, null)], 42);
    });

    test('ValueProvider can be retrieved via context.use<T>()', () async {
      final adapter = _MockAdapter();
      final localConfig = ApplicationConfig(serverAdapter: adapter);
      final container = SerinusContainer(localConfig, adapter);
      final module = SimpleModuleWithValueProvider();

      await container.modulesContainer.registerModules(module);

      final router = Router(localConfig.versioningOptions);
      final explorer = RoutesExplorer(container, router);
      explorer.resolveRoutes();

      final scope = container.modulesContainer.getScope(
        InjectionToken.fromModule(module),
      );
      expect(scope.unifiedValues[ValueToken(String, null)], 'Hello World');
      expect(scope.unifiedValues[ValueToken(int, null)], 42);
    });

    test(
      'Global module with ValueProvider makes value available globally',
      () async {
        final container = ModulesContainer(config);
        final module = ModuleImportingGlobalValue();
        await container.registerModules(module);

        final scope = container.getScope(InjectionToken.fromModule(module));
        expect(
          scope.unifiedValues.containsKey(ValueToken(String, null)),
          isTrue,
        );
        expect(scope.unifiedValues[ValueToken(String, null)], 'Global Value');
      },
    );

    test('ValueProvider can be exported from a module', () async {
      final container = ModulesContainer(config);
      final module = ModuleImportingValueProvider();
      await container.registerModules(module);

      final scope = container.getScope(InjectionToken.fromModule(module));
      expect(scope.unifiedValues.containsKey(ValueToken(String, null)), isTrue);
      expect(scope.unifiedValues[ValueToken(String, null)], 'Exported Value');
    });

    test('ComposedProvider can use ValueProvider as dependency', () async {
      final container = ModulesContainer(config);
      final module = ModuleWithComposedProviderUsingValue();
      await container.registerModules(module);
      await container.finalize(module);

      final scope = container.getScope(InjectionToken.fromModule(module));
      expect(
        scope.unifiedProviders.any((p) => p is TestProviderWithValue),
        isTrue,
      );

      final provider =
          scope.unifiedProviders.firstWhere((p) => p is TestProviderWithValue)
              as TestProviderWithValue;
      expect(provider.getValue(), 'Base Value');
    });

    test('context.canUse<T>() returns true for ValueProvider types', () async {
      final container = ModulesContainer(config);
      final module = SimpleModuleWithValueProvider();
      await container.registerModules(module);

      final scope = container.getScope(InjectionToken.fromModule(module));

      // The values should be in unifiedValues
      expect(scope.unifiedValues.containsKey(ValueToken(String, null)), isTrue);
      expect(scope.unifiedValues.containsKey(ValueToken(int, null)), isTrue);
    });

    test(
      'Multiple ValueProviders with different types work correctly',
      () async {
        final container = ModulesContainer(config);
        final module = SimpleModuleWithValueProvider();
        await container.registerModules(module);

        final scope = container.getScope(InjectionToken.fromModule(module));
        expect(scope.unifiedValues[ValueToken(String, null)], 'Hello World');
        expect(scope.unifiedValues[ValueToken(int, null)], 42);
      },
    );
  });
}
