# Task Scheduling

Task scheduling allows you to execute code at fixed date/time, at recurring intervals, or once after a certain time. This is useful for tasks like sending emails, cleaning up databases, etc.
For Dart applications (Flutter or server-side), you can use the `cron` package for scheduling tasks.

Serinus provides `serinus_schedule` which integrates the `cron` package and provides a set of tools to schedule tasks in your application. Let's dive into the details of how to use it.

## Installation

To install Serinus Schedule you can use the following command:

```bash
dart pub add serinus_schedule
```

To activate the Module you can import it in your application as follows:

```dart
import 'package:serinus/serinus.dart';
import 'package:serinus_schedule/serinus_schedule.dart';

class AppModule extends Module {

  AppModule(): super(
    imports: [
      ScheduleModule()
    ]
  )

}

```

You can now use it inside your `Module` scope to initialize other providers or in the `RequestContext` when dealing with requests.

## Cron Jobs

The first and, probably, most common way to schedule tasks is using cron jobs. Cron jobs are scheduled tasks that run at specific intervals. You can use the `addCronJob` method to add a cron job to your application. When creating it you must specify the name, the cron expression and the function to execute. The function must return `Future<void>`.

```dart
import 'package:serinus/serinus.dart';
import 'package:serinus_schedule/serinus_schedule.dart';

class AppModule extends Module {

  AppModule(): super(
    imports: [
      ScheduleModule()
    ],
    controllers: [
      AppController()
    ],
  )

}

class AppController extends Controller {

  AppController(): super('/') {
    on(Route.get('/'), (RequestContext context) async {
      final registry = context.use<ScheduleRegistry>();
      registry.addCronJob(
        'hello',
        '*/5 * * * *',
        () async {
          print('Hello world');
        }
      );
      return 'Cron job scheduled';
    });
  }

}
```

This method returns a `CronJob` object which can be used to manage the job. You can use the `stop`, `restart` methods to control the job and. You can also use the `isRunning` property to check if the job is running or not.

In the table you can find all the available methods and properties of the `CronJob` class:

| Method | Description |
| ------- | ----------- |
| `stop` | Stops the cron job. |
| `restart` | Restarts the cron job. |
| `isRunning` | Returns true if the cron job is running, false otherwise. |
| `name` | Returns the name of the cron job. |
| `schedule` | Returns the `Schedule` of the cron job. |
| `nextDate` | Returns the next invocation date |
| `lastDate` | Returns the last invocation date |
| `nextDates` | Returns the next execution dates |

Also the `ScheduleRegistry` class provides some methods to manage the map of cron jobs. You can use the `getCronJob` method to get a cron job by name, the `jobs` getter to get all the cron jobs and the `cancelCronJob` method to remove a cron job by name.

| Method | Description |
| ------- | ----------- |
| `getCronJob` | Returns a cron job by name. |
| `cancelCronJob` | Stops a cron job by name. |
| `jobs` | Returns all the cron jobs. |
| `removeCronJob` | Removes the cron job from the registry without stopping it |
| `addCronJob` | Adds a cron job to the registry |

## Timeouts

Timeouts are used to execute a function after a certain time, they are executed only once. You can use the `addTimeout` method to add a timeout to your application. When creating it you must specify the name, the duration and the function to execute. The function must return `Future<void>`.

```dart

addTimeout(RequestContext context) {
  final registry = context.use<ScheduleRegistry>();
  registry.addTimeout(
    'hello',
    Duration(seconds: 5),
    () async {
      print('Hello world');
    }
  );
}
```

The `addTimeout` method returns a `Timer` object. As for the cron jobs, you can use the `cancelTimeout` method to stop the timeout by name, the `getTimeout` method to get a timeout by name and the `removeTimeout` method to remove the timeout from the registry without stopping it.

| Method | Description |
| ------- | ----------- |
| `getTimeout` | Returns a timeout by name. |
| `cancelTimeout` | Stops a timeout by name. |
| `removeTimeout` | Removes the timeout from the registry without stopping it |
| `addTimeout` | Adds a timeout to the registry |
| `timeouts` | Returns all the timeouts. |

## Intervals

Intervals are used to execute a function at a certain interval, they are executed repeatedly. You can use the `addInterval` method to add an interval to your application. When creating it you must specify the name, the duration and the function to execute. The function must return `Future<void>`.

```dart
addTimeout(RequestContext context) {
  final registry = context.use<ScheduleRegistry>();
  registry.addInterval(
    'hello',
    Duration(seconds: 5),
    () async {
      print('Hello world');
    }
  );
}
```

The `addInterval` method returns a `Timer` object. As for the cron jobs, you can use the `cancelInterval` method to stop the interval by name, the `getInterval` method to get an interval by name and the `removeInterval` method to remove the interval from the registry without stopping it.

| Method | Description |
| ------- | ----------- |
| `getInterval` | Returns an interval by name. |
| `cancelInterval` | Stops an interval by name. |
| `removeInterval` | Removes the interval from the registry without stopping it |
| `addInterval` | Adds an interval to the registry |
| `intervals` | Returns all the intervals. |
