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
      this.connections = 256,
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

    for (final rawLine in lines) {
      final line = rawLine.trim();
      if (line.isEmpty) continue;

      final reqsMatch = RegExp(r'(Requests/sec|Reqs/sec):?\s+([0-9]+\.?[0-9]*)')
          .firstMatch(line);
      if (reqsMatch != null) {
        result.rps = double.tryParse(reqsMatch.group(2)!) ?? result.rps;
      }

      if (line.startsWith('Latency')) {
        final parts = line
            .split(RegExp(r'\s+'))
            .where((e) => e.isNotEmpty)
            .toList();
        // Expected: Latency  X  Y  Z
        if (parts.length >= 4) {
          result.avgLatency = _tryParseNumber(parts[1]);
          result.stdevLatency = _tryParseNumber(parts[2]);
          result.maxLatency = _tryParseNumber(parts[3]);
        }
      }

      if (line.startsWith('Requests:')) {
        final parts = line.split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
        if (parts.length >= 2) {
          result.requests = int.tryParse(parts[1]) ?? result.requests;
        }
      }

      if (line.startsWith('transfered:') || line.startsWith('transferred:')) {
        final parts = line.split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
        if (parts.length >= 2) {
          result.readSize = double.tryParse(parts[1]) ?? result.readSize;
          result.transferRate = result.readSize / duration.inSeconds / 1024 / 1024 > 1
              ? '${(result.readSize / duration.inSeconds / 1024 / 1024).toStringAsFixed(2)} MB/s'
              : '${(result.readSize / duration.inSeconds / 1024).toStringAsFixed(2)} KB/s';
        }
      }
    }

    return result;
  }

  double _tryParseNumber(String value) {
    return double.tryParse(value.replaceAll(RegExp(r'[^0-9\.-]'), '')) ?? 0;
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

  Map<String, dynamic> toJson() {
    return {
      'minLatency': minLatency,
      'avgLatency': avgLatency,
      'stdevLatency': stdevLatency,
      'maxLatency': maxLatency,
      'stdevPerc': stdevPerc,
      'rpsAvg': rpsAvg,
      'rpsMax': rpsMax,
      'rpdStdev': rpdStdev,
      'rpsPerc': rpsPerc,
      'latency50': latency50,
      'latency75': latency75,
      'latency90': latency90,
      'latency99': latency99,
      'requests': requests,
      'readSize': readSize,
      'rps': rps,
      'transferRate': transferRate,
    };
  }

  static Result fromJson(Map<String, dynamic> json) {
    final result = Result();
    result.minLatency = (json['minLatency'] ?? 0).toDouble();
    result.avgLatency = (json['avgLatency'] ?? 0).toDouble();
    result.stdevLatency = (json['stdevLatency'] ?? 0).toDouble();
    result.maxLatency = (json['maxLatency'] ?? 0).toDouble();
    result.stdevPerc = (json['stdevPerc'] ?? 0).toDouble();
    result.rpsAvg = (json['rpsAvg'] ?? 0).toDouble();
    result.rpsMax = (json['rpsMax'] ?? 0).toDouble();
    result.rpdStdev = (json['rpdStdev'] ?? 0).toDouble();
    result.rpsPerc = (json['rpsPerc'] ?? 0).toDouble();
    result.latency50 = (json['latency50'] ?? 0).toDouble();
    result.latency75 = (json['latency75'] ?? 0).toDouble();
    result.latency90 = (json['latency90'] ?? 0).toDouble();
    result.latency99 = (json['latency99'] ?? 0).toDouble();
    result.requests = (json['requests'] ?? 0).toInt();
    result.readSize = (json['readSize'] ?? 0).toDouble();
    result.rps = (json['rps'] ?? 0).toDouble();
    result.transferRate = json['transferRate']?.toString() ?? '0';
    return result;
  }

  @override
  String toString() {
    return 'Result{minLatency: $minLatency, avgLatency: $avgLatency, stdevLatency: $stdevLatency, maxLatency: $maxLatency, stdevPerc: $stdevPerc, rpsAvg: $rpsAvg, rpsMax: $rpsMax, rpdStdev: $rpdStdev, rpsPerc: $rpsPerc, latency50: $latency50, latency75: $latency75, latency90: $latency90, latency99: $latency99, requests: $requests, readSize: $readSize, rps: $rps, transferRate: $transferRate}';
  }
}
