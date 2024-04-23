import 'dart:async';
import 'dart:convert';
import 'dart:io';

abstract class SerinusBenchmark {
  final int connections;
  final String name;
  final int threads;
  final Duration duration;

  final List<IterResult> results = [];

  SerinusBenchmark({
    this.name = 'SerinusBenchmark',
    this.connections = 1024,
    this.threads = 8,
    this.duration = const Duration(seconds: 10)
  });
    
  Future<void> setup();

  Future<void> measureWeb() async {
    await setup();
    print("Running $name wrk with $threads threads, $connections connections, and ${duration.inSeconds} duration");
    final process = await Process.start('wrk', ['-t$threads', '-c$connections', '-d${duration.inSeconds}s', '--latency', 'http://localhost:3000/']);
    process.stdout.transform(utf8.decoder).listen(print);
    await process.exitCode;
    await teardown();
  }

  Future<void> report() async {
    await measureWeb();
  }

  Future<void> teardown();

}

class PartialMeasurement {

  final int elapsedMicros;
  final int iterations;
  double get requestsPerSecond => requestsTotal / (elapsedMicros / 1000000);
  final double requestsTotal;

  PartialMeasurement(this.elapsedMicros, this.iterations, this.requestsTotal);

  @override
  String toString() {
    return 'Elapsed time: $elapsedMicros, Iterations: $iterations, Requests: $requestsTotal, Requests per second: $requestsPerSecond';
  }
}

class IterResult {

  final int elapsedTime;
  final int statusCode;
  final int iter;

  IterResult(this.elapsedTime, this.statusCode, this.iter);

}