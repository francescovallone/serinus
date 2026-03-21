# Health Checks

Healthchecks are crucial when it comes to complex backend setups. They allow you to monitor the health of your application and ensure that it is running smoothly. Most of the time, a health check is a simple endpoint that returns a status code indicating whether the application is healthy or not.

Serinus provides the `HealthCheckModule`, which allows you to easily create health check endpoints for your application.

## Getting Started

To get started with health checks in Serinus, you nbeed to install the `serinus_health_checks` package:

```bash
dart pub add serinus_health_checks
```

## Setting up a Health Check

An health check represents a summary of health indicators. A health indicators executes a check of a server to determine if it is healthy or not. `serinus_health_checks` provides a set of built-in health indicators, such as:

- `MemoryHealthIndicator`: checks the memory usage of the application.
- `DiskHealthIndicator`: checks the disk usage of the application.
- `HttpPingIndicator`: checks the availability of an HTTP endpoint.
- `LoxiaHealthIndicator`: checks the connectivity to a database through `loxia`.

To get start with your health checks, you can add the `HealthCheckModule` to your Serinus application and configure it with the desired health indicators. For example:

```dart
import 'package:serinus/serinus.dart';
import 'package:serinus_health_checks/serinus_health_checks.dart';

class AppModule extends Module {
  AppModule()
	: super(
		imports: [
		  HealthCheckModule(
			indicators: [
			  MemoryHealthIndicator(),
			  DiskHealthIndicator(),
			  HttpPingIndicator('example', 'https://example.com'),
			],
		  ),
		],
		controllers: [AppController()],
	  );
}
```

In this example, we have added three health indicators: `MemoryHealthIndicator`, `DiskHealthIndicator`, and `HttpPingIndicator`. The `HttpPingIndicator` checks the availability of the `https://example.com` endpoint.

## Custom Health Indicators

In some cases the provided health indicators may not be sufficient for your needs. In such cases, you can create your own custom health indicators by implementing the `HealthIndicator` interface. For example:

```dart
import 'package:serinus_health_checks/serinus_health_checks.dart';

class CustomHealthIndicator implements HealthIndicator {
  @override
  Future<HealthIndicatorCheck> pingCheck() async {
	// Perform your custom health check logic here
	final isHealthy = await performCustomCheck();

	return (
		status: isHealth ? HealthStatus.up : HealthStatus.down,
		details: {'custom': 'Custom health check result'},
	);
  }
}
```

In this example, we have created a custom health indicator called `CustomHealthIndicator`. The `pingCheck` method contains the logic for performing the health check and returns a `HealthIndicatorCheck` record that indicates whether the application is healthy or not, along with any additional details.