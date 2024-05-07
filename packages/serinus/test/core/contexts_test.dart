import 'package:serinus/serinus.dart';
import 'package:test/test.dart';

class TestProvider extends Provider {
  TestProvider();
}

void main() async {
  group('$ApplicationContext', () {
    test(
        'when a $ApplicationContext is created, then it should have a list of providers',
        () {
      final context = ApplicationContext({}, 'test');

      expect(context.providers, {});
    });

    test(
        'when a provider is added to the context, then it should be available to be used',
        () {
      final context = ApplicationContext({}, 'test');
      final provider = TestProvider();

      context.addProviderToContext(provider);

      expect(context.use<TestProvider>(), provider);
    });

    test(
        'when a provider is not available in the context, then a StateError should be thrown',
        () {
      final context = ApplicationContext({}, 'test');

      expect(() => context.use<TestProvider>(), throwsStateError);
    });
  });
}
