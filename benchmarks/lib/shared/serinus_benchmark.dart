import 'dart:async';
import 'dart:convert';
import 'dart:io';

abstract class SerinusBenchmark {
  final int connections;
  final String name;
  final int threads;
  final Duration duration;

  SerinusBenchmark(
      {this.name = 'SerinusBenchmark',
      this.connections = 1024,
      this.threads = 8,
      this.duration = const Duration(seconds: 10)});

  Future<void> setup();

  Future<Result?> measureWeb() async {
    await setup();
    print(
        "Running $name wrk with $threads threads, $connections connections, and ${duration.inSeconds}s duration");
    final process = await Process.start('wrk', [
      '-t$threads',
      '-c$connections',
      '-d${duration.inSeconds}s',
      '--latency',
      'http://localhost:3000/'
    ]);
    Result? result;
    process.stdout.transform(utf8.decoder).listen((message) {
      print(message);
      result = _parseResult(message);
    });
    process.stderr.transform(utf8.decoder).listen((message) {
      print(message);
    });
    await process.exitCode;
    await teardown();
    return result;
  }

  Result _parseResult(String stdout) {
    final lines = stdout.split('\n');
    final result = Result();
    for (var line in lines) {
      final segments = line
          .split(' ')
          .map((e) => e.trim())
          .where((element) => element.isNotEmpty)
          .toList();
      if (segments.isNotEmpty) {
        final segment = segments[0];
        if (segment.contains('Requests/sec:')) {
          result.rps = double.parse(segments[1]);
        }
        if (segment.contains('Transfer/sec:')) {
          result.transferRate = segments[1];
        }
        if (segment == 'Latency' && segments[1] != 'Distribution') {
          result.avgLatency =
              double.parse(segments[1].replaceAll(RegExp(r'[A-Za-z]+'), ''));
          result.stdevLatency =
              double.parse(segments[2].replaceAll(RegExp(r'[A-Za-z]+'), ''));
          result.maxLatency =
              double.parse(segments[3].replaceAll(RegExp(r'[A-Za-z]+'), ''));
          result.stdevPerc = double.parse(segments[4].replaceAll('%', ''));
        }
        if (segment == 'Req/Sec') {
          result.rpsAvg =
              double.parse(segments[1].replaceAll(RegExp(r'[A-Za-z]+'), ''));
          result.rpdStdev =
              double.parse(segments[2].replaceAll(RegExp(r'[A-Za-z]+'), ''));
          result.rpsMax =
              double.parse(segments[3].replaceAll(RegExp(r'[A-Za-z]+'), ''));
          result.rpsPerc = double.parse(segments[4].replaceAll('%', ''));
        }
      }
    }
    return result;
  }

  Future<Result?> report() async {
    return await measureWeb();
  }

  Future<void> teardown();
}

class Result {
  double avgLatency = 0;
  double stdevLatency = 0;
  double maxLatency = 0;
  double stdevPerc = 0;
  double rpsAvg = 0;
  double rpsMax = 0;
  double rpdStdev = 0;
  double rpsPerc = 0;
  double latency50 = 0;
  double latency75 = 0;
  double latency90 = 0;
  double latency99 = 0;
  int requests = 0;
  double readSize = 0;
  double rps = 0;
  String transferRate = '0';

  Result();
}
