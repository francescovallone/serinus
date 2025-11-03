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
    Result? result;
    if(Platform.isWindows){
      result = await _executeWinrkBenchmark();
    }else{
      result = await _executeWrkBenchmark();
    }
    await teardown();
    return result;
  }

  Future<Result> _executeWrkBenchmark() async {
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
      result = _parseWrkResult(message);
    });
    process.stderr.transform(utf8.decoder).listen((message) {
      print(message);
    });
    await process.exitCode;
    return result!;
  }

  Result _parseWrkResult(String stdout) {
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
  
  Future<Result?> _executeWinrkBenchmark() async {
    final process = await Process.start('bombardier', [
      '-c',
      '$connections',
      '-d',
      '${duration.inSeconds}s',
      'http://localhost:3000/',
    ]);
    Result? result;
    final resultMessage = StringBuffer();
    process.stdout.transform(utf8.decoder).listen((message) {
      resultMessage.writeln(message);
    });
    process.stderr.transform(utf8.decoder).listen((message) {
      print(message);
    });
    await process.exitCode;
    print(resultMessage);
    result = _parseWinrkResult(resultMessage.toString());
    return result;
  }

  Result _parseWinrkResult(String stdout) {
    final lines = stdout.split('\n');
    final result = Result();
    bool metResultString = false;
    for (var line in lines) {
      final segments = line
          .split(' ')
          .map((e) => e.trim())
          .where((element) => element.isNotEmpty)
          .toList();
      if (segments.isNotEmpty) {
        if(!metResultString){
          metResultString = segments[0] == 'Result:';
        }
        if(metResultString){
          final segment = segments[0];
          if (segment.contains('total:')) {
            result.requests = int.parse(segments[1]);
          }
          if (segment.contains('transfers:')) {
            result.readSize = double.parse(segments[1]);
            result.transferRate = result.readSize / duration.inSeconds / 1024 / 1024 > 1 
              ? '${(result.readSize / duration.inSeconds / 1024 / 1024).toStringAsFixed(2)} MB/s' 
              : '${(result.readSize / duration.inSeconds / 1024).toStringAsFixed(2)} KB/s';
          }
          if (segments[0] == 'latency') {
            switch(segments[1]){
              case 'min:':
                result.minLatency = double.parse(segments[2].replaceAll(RegExp(r'[A-Za-z]+'), ''));
                break;
              case 'average:':
                result.avgLatency = double.parse(segments[2].replaceAll(RegExp(r'[A-Za-z]+'), ''));
                break;
              case 'max:':
                result.maxLatency = double.parse(segments[2].replaceAll(RegExp(r'[A-Za-z]+'), ''));
                break;
              case 'median:':
                result.stdevLatency = double.parse(segments[2].replaceAll(RegExp(r'[A-Za-z]+'), ''));
                break;
            }
          }
          if (segments[0] == 'rps:') {
            result.rps = double.parse(segments[1]);
          }
        }
      }
    }
    return result;
  }
  
}

class Result {
  double minLatency = 0;
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

  @override
  String toString() {
    return 'Result{minLatency: $minLatency, avgLatency: $avgLatency, stdevLatency: $stdevLatency, maxLatency: $maxLatency, stdevPerc: $stdevPerc, rpsAvg: $rpsAvg, rpsMax: $rpsMax, rpdStdev: $rpdStdev, rpsPerc: $rpsPerc, latency50: $latency50, latency75: $latency75, latency90: $latency90, latency99: $latency99, requests: $requests, readSize: $readSize, rps: $rps, transferRate: $transferRate}';
  }
}
