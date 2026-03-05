# Observability

Observability is the ability to understand how your application behaves while it is running.

In practice, this usually means combining:

- **Logs** (human-readable events)
- **Metrics** (numeric measurements over time)
- **Traces** (step-by-step execution for a single request)

In Serinus, the `observe` feature helps you collect **traces** for each request.

## Quick start

Enable observability by calling `application.observe(...)`.

```dart
import 'package:serinus/serinus.dart';

void main() async {
	final application = await serinus.createApplication(
		entrypoint: AppModule(),
	);

	application.observe(
		ObserveConfig(
			enabled: true,
			sinks: [LoggerObserveSink()],
		),
	);

	await application.serve();
}
```

Now Serinus can create traces and send them to the sink (`LoggerObserveSink` in this example).

## What gets traced

A trace represents one request execution.

It includes:

- route id
- request path and method
- controller type
- a list of steps with duration and errors

Steps can belong to phases like:

- `ObservePhase.routing`
- `ObservePhase.requestHook`
- `ObservePhase.middleware`
- `ObservePhase.handle`
- `ObservePhase.response`
- `ObservePhase.exception`

## Observe only what you care about

You can limit observability to specific routes, controllers, phases, or step names.

```dart
application.observe(
	ObserveConfig(
		enabled: true,
		routes: {'users.findAll', 'users.findById'},
		phases: {ObservePhase.handle, ObservePhase.exception},
		stepNames: {'handler.UsersController.findAll'},
		sinks: [LoggerObserveSink()],
	),
);
```

If you leave these sets empty, Serinus observes everything (when enabled).

## Sampling (watch some requests, not all)

In production, you may not want to collect every trace.

`ObserveSampling` lets you collect a deterministic subset of requests.

```dart
application.observe(
	ObserveConfig(
		enabled: true,
		sampling: ObserveSampling(modulus: 10, acceptBucket: 0),
		sinks: [LoggerObserveSink()],
	),
);
```

The example above keeps about **1 request out of 10**.

## Add your own sink

A sink is the destination for completed traces (console, file, APM, database, and so on).

```dart
class MyObserveSink implements ObserveSink {
	@override
	Future<void> consume(ObserveSinkInput input) async {
		final trace = input.trace;
		print('Trace ${trace.id.value} on ${trace.path}');
	}
}

application.observe(
	ObserveConfig(
		enabled: true,
		sinks: [MyObserveSink()],
	),
);
```

## User key for sticky sampling

If you want the same user to be sampled consistently, provide a `userKeyExtractor`.

```dart
application.observe(
	ObserveConfig(
		enabled: true,
		sampling: ObserveSampling(modulus: 100, acceptBucket: 7),
		userKeyExtractor: (input) {
			return input.requestContext.request.headers['x-user-id'];
		},
		sinks: [LoggerObserveSink()],
	),
);
```

## Custom tracer

If you need full control (for example OpenTelemetry), provide a custom tracer with `tracer:`.

When `tracer` is set:

- handle activation is delegated to your tracer
- flush is delegated to your tracer

Use this only when `ObserveSink` is not enough for your use case.

