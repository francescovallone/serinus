import 'dart:convert';
import 'dart:io';

import 'package:serinus/serinus.dart';
import 'package:test/test.dart';

const _testPort = 3017;

class _TraceCaptureHook extends Hook with OnResponse {
  static final Map<String, List<TraceStep>> tracesByPath = {};

  static void capture(ExecutionContext context) {
    final path = context.switchToHttp().path;
    final steps = context.observe?.trace.steps;
    if (steps == null) {
      return;
    }
    tracesByPath[path] = List<TraceStep>.from(steps);
  }

  static void reset() {
    tracesByPath.clear();
  }

  @override
  Future<void> onResponse(
    ExecutionContext context,
    WrappedResponse data,
  ) async {
    capture(context);
  }
}

class _ObservePipelineMiddleware extends Middleware {
  const _ObservePipelineMiddleware();

  @override
  Future<void> use(ExecutionContext context, NextFunction next) async {
    await next();
  }
}

class _ObservePipelinePipe extends Pipe {
  const _ObservePipelinePipe();

  @override
  Future<void> transform(ExecutionContext context) async {}
}

class _ObservePipelineExceptionFilter extends ExceptionFilter {
  const _ObservePipelineExceptionFilter()
    : super(catchTargets: const [BadRequestException]);

  @override
  Future<void> onException(
    ExecutionContext context,
    Exception exception,
  ) async {
    context.response.body = 'handled-exception';
    _TraceCaptureHook.capture(context);
  }
}

class _ObservePipelineController extends Controller {
  _ObservePipelineController() : super('/') {
    pipes = [const _ObservePipelinePipe()];
    on(Route.get('/ok'), (RequestContext context) async => 'ok');
    on(Route.get('/boom'), (RequestContext context) async {
      throw BadRequestException('boom');
    });
  }

  @override
  Set<ExceptionFilter> get exceptionFilters => {
    const _ObservePipelineExceptionFilter(),
  };
}

class _ObservePipelineModule extends Module {
  _ObservePipelineModule() : super(controllers: [_ObservePipelineController()]);

  @override
  void configure(MiddlewareConsumer consumer) {
    consumer.apply([const _ObservePipelineMiddleware()]).forControllers([
      _ObservePipelineController,
    ]);
  }
}

void main() {
  group('Automatic pipeline observability', () {
    SerinusApplication? app;

    setUpAll(() async {
      app = await serinus.createApplication(
        entrypoint: _ObservePipelineModule(),
        port: _testPort,
        logLevels: {LogLevel.none},
      );
      app!.observe(ObserveConfig(enabled: true));
      app!.use(RequestHook((_) async {}));
      app!.use(BeforeHook((_) {}));
      app!.use(AfterHook((_, __) {}));
      app!.use(_TraceCaptureHook());
      await app!.serve();
    });

    setUp(() {
      _TraceCaptureHook.reset();
    });

    tearDownAll(() async {
      await app?.close();
    });

    test(
      'captures route/hooks/pipes/middlewares/handler/response automatically',
      () async {
        final request = await HttpClient().getUrl(
          Uri.parse('http://localhost:$_testPort/ok'),
        );
        final response = await request.close();
        final body = await response.transform(utf8.decoder).join();

        expect(response.statusCode, 200);
        expect(body, 'ok');

        final steps = _TraceCaptureHook.tracesByPath['/ok'];
        expect(steps, isNotNull);
        expect(steps!, isNotEmpty);

        expect(steps.any((s) => s.name.startsWith('route.')), isTrue);
        expect(steps.any((s) => s.phase == ObservePhase.requestHook), isTrue);
        expect(steps.any((s) => s.name.startsWith('pipe.')), isTrue);
        expect(steps.any((s) => s.name.startsWith('middleware.')), isTrue);
        expect(steps.any((s) => s.name.startsWith('beforeHandle.')), isTrue);
        expect(steps.any((s) => s.name.startsWith('handler.')), isTrue);
        expect(steps.any((s) => s.name.startsWith('afterHandle.')), isTrue);
        expect(steps.any((s) => s.name.startsWith('response.')), isTrue);

        expect(steps.any((s) => s.phase == ObservePhase.routing), isTrue);
        expect(steps.any((s) => s.phase == ObservePhase.pipe), isTrue);
        expect(steps.any((s) => s.phase == ObservePhase.middleware), isTrue);
        expect(steps.any((s) => s.phase == ObservePhase.beforeHandle), isTrue);
        expect(steps.any((s) => s.phase == ObservePhase.handle), isTrue);
        expect(steps.any((s) => s.phase == ObservePhase.afterHandle), isTrue);
        expect(steps.any((s) => s.phase == ObservePhase.response), isTrue);
      },
    );

    test('captures exception filters automatically', () async {
      final request = await HttpClient().getUrl(
        Uri.parse('http://localhost:$_testPort/boom'),
      );
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();

      expect(response.statusCode, 400);
      expect(body, 'handled-exception');

      final steps = _TraceCaptureHook.tracesByPath['/boom'];
      expect(steps, isNotNull);
      expect(steps!, isNotEmpty);

      final handlerStep = steps.firstWhere(
        (s) => s.name.startsWith('handler.'),
      );
      expect(handlerStep.success, isFalse);

      expect(steps.any((s) => s.name.startsWith('exception.')), isTrue);
      expect(steps.any((s) => s.phase == ObservePhase.exception), isTrue);
      expect(steps.any((s) => s.phase == ObservePhase.response), isTrue);
    });
  });
}
