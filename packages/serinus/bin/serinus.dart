// coverage:ignore-file
// ignore_for_file: avoid_print
import 'dart:async';
import 'dart:io';

import 'package:serinus/serinus.dart';

class TestProvider extends Provider {
  final List<String> testList = [
    'Hello',
    'World',
  ];

  TestProvider({super.isGlobal});

  String testMethod() {
    testList.add('Hello world');
    return 'Hello world';
  }
}

class TestProviderTwo extends Provider
    with OnApplicationInit, OnApplicationShutdown {
  final TestProviderThree testProvider;

  TestProviderTwo(this.testProvider);

  String testMethod() {
    return 'from provider two';
  }

  @override
  Future<void> onApplicationInit() async {
    print('Provider two initialized');
  }

  @override
  Future<void> onApplicationShutdown() async {
    print('Provider two shutdown');
  }
}

class TestProviderThree extends Provider with OnApplicationInit {
  final TestProvider testProvider;

  TestProviderThree(this.testProvider);

  @override
  Future<void> onApplicationInit() async {
    print('Provider three initialized');
  }
}

class TestProviderFour extends Provider with OnApplicationInit {
  final TestProviderThree testProvider;

  final TestProviderTwo testProviderTwo;

  TestProviderFour(this.testProvider, this.testProviderTwo);

  @override
  Future<void> onApplicationInit() async {
    print('Provider four initialized');
  }
}

class CircularDependencyModule extends Module {
  CircularDependencyModule()
      : super(imports: [], controllers: [], providers: [
          Provider.deferred((TestProvider tp) => TestProviderThree(tp),
              inject: [TestProvider], type: TestProviderThree),
        ], exports: [
          TestProviderThree
        ], middlewares: []);
}

class AnotherModule extends Module {
  AnotherModule()
      : super(imports: [], controllers: [], providers: [
          Provider.deferred(
              (TestProviderTwo tp, TestProviderThree t) =>
                  TestProviderFour(t, tp),
              inject: [TestProviderTwo, TestProviderThree],
              type: TestProviderFour),
        ], middlewares: []);
}

class AppModule extends Module {
  AppModule()
      : super(imports: [
          AnotherModule(),
          CircularDependencyModule()
        ], controllers: [
          AppController()
        ], providers: [
          TestProvider(isGlobal: true),
          Provider.deferred((TestProviderThree tp) => TestProviderTwo(tp),
              inject: [TestProviderThree], type: TestProviderTwo),
        ], middlewares: []);
}

class AppController extends Controller {
  AppController({super.path = '/'}) {
    onStatic(Route.get('/'), 'ok!');
    // on(Route.get('/1'), (context) async* {
    //   yield 1;
    //   Future.delayed(Duration(seconds: 2));
    //   yield 2;
    // });
    on(Route.get('/2'), (context) async {
      return 2;
    });
  }
}

void main(List<String> arguments) async {
  SerinusApplication application = await serinus.createApplication(
      entrypoint: AppModule(), host: InternetAddress.anyIPv4.address);
  application.enableShutdownHooks();
  // application.trace(ServerTimingTracer());
  await application.serve();
}
