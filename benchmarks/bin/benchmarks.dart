import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:benchmarks/benchmarks.dart' as benchmarks;
import 'package:benchmarks/shared/serinus_benchmark.dart';

const _defaultRuns = 5;
const _defaultOutputDir = 'benchmarks/results';

class _Config {
  _Config({
    required this.tag,
    required this.runs,
    required this.outputDir,
    required this.runId,
    required this.only,
  });

  final String tag;
  final int runs;
  final String outputDir;
  final String runId;
  final List<String> only;
}

class _Scenario {
  _Scenario(this.name, this.runner);

  final String name;
  final Future<Result?> Function() runner;
}

Future<void> main(List<String> arguments) async {
  final config = _parseArgs(arguments);
  final sanitizedRunId = config.runId.replaceAll(':', '-');
  final selected = _scenarios
      .where((s) => config.only.isEmpty || config.only.contains(s.name))
      .toList();

  if (selected.isEmpty) {
    stderr.writeln('No scenarios selected.');
    exitCode = 1;
    return;
  }

  final results = <String, List<Result>>{};
  for (final scenario in selected) {
    stdout.writeln(
        'Running scenario ${scenario.name} for tag ${config.tag} (${config.runs} runs)...');
    final samples = <Result>[];
    for (var i = 0; i < config.runs; i++) {
      final result = await scenario.runner();
      if (result != null) {
        samples.add(result);
      }
    }
    results[scenario.name] = samples;
    await _persistScenario(
      scenario: scenario.name,
      samples: samples,
      config: config,
      runId: sanitizedRunId,
    );
  }

  _printSummary(results, config.tag);
}

Future<void> _persistScenario({
  required String scenario,
  required List<Result> samples,
  required _Config config,
  required String runId,
}) async {
  final dir = Directory('${config.outputDir}/$scenario/$runId');
  await dir.create(recursive: true);
  final file = File('${dir.path}/${config.tag}.json');
  final payload = {
    'tag': config.tag,
    'scenario': scenario,
    'runId': runId,
    'runs': samples.map((r) => r.toJson()).toList(),
    'stats': _buildStats(samples),
  };
  await file.writeAsString(const JsonEncoder.withIndent('  ').convert(payload));
  stdout.writeln('Saved ${file.path}');
}

Map<String, dynamic> _buildStats(List<Result> samples) {
  if (samples.isEmpty) {
    return {
      'count': 0,
      'rpsMean': 0,
      'rpsStddev': 0,
      'rpsMin': 0,
      'rpsMax': 0,
    };
  }

  final rpsValues = samples.map((e) => e.rps).toList();
  final mean = _mean(rpsValues);
  final stddev = _stddev(rpsValues, mean);
  return {
    'count': samples.length,
    'rpsMean': mean,
    'rpsStddev': stddev,
    'rpsMin': rpsValues.reduce((a, b) => a < b ? a : b),
    'rpsMax': rpsValues.reduce((a, b) => a > b ? a : b),
  };
}

void _printSummary(Map<String, List<Result>> results, String tag) {
  stdout.writeln('Summary for $tag');
  results.forEach((scenario, samples) {
    final stats = _buildStats(samples);
    final count = stats['count'] as int;
    final mean = stats['rpsMean'] as double;
    final stddev = stats['rpsStddev'] as double;
    stdout.writeln(
        '- $scenario: n=$count rpsMean=${mean.toStringAsFixed(2)} rpsStddev=${stddev.toStringAsFixed(2)}');
  });
}

double _mean(List<double> values) {
  if (values.isEmpty) return 0;
  return values.reduce((a, b) => a + b) / values.length;
}

double _stddev(List<double> values, double mean) {
  if (values.length < 2) return 0;
  final variance =
      values.map((v) => (v - mean) * (v - mean)).reduce((a, b) => a + b) /
          (values.length - 1);
  return variance.sqrt();
}

extension on double {
  double sqrt() => math.sqrt(this);
}

_Config _parseArgs(List<String> args) {
  var runs = _defaultRuns;
  var tag = 'dev';
  var outputDir = _defaultOutputDir;
  var runId = DateTime.now().toUtc().toIso8601String();
  final only = <String>[];

  for (final arg in args) {
    if (arg.startsWith('--runs=')) {
      runs = int.tryParse(arg.substring('--runs='.length)) ?? _defaultRuns;
    } else if (arg.startsWith('--tag=')) {
      tag = arg.substring('--tag='.length);
    } else if (arg.startsWith('--output-dir=')) {
      outputDir = arg.substring('--output-dir='.length);
    } else if (arg.startsWith('--run-id=')) {
      runId = arg.substring('--run-id='.length);
    } else if (arg.startsWith('--only=')) {
      only.addAll(arg.substring('--only='.length).split(',').where((e) => e.isNotEmpty));
    }
  }

  return _Config(
    tag: tag,
    runs: runs,
    outputDir: outputDir,
    runId: runId,
    only: only,
  );
}

final _scenarios = <_Scenario>[
  _Scenario('serinus', () => benchmarks.SerinusAppBenchmark().report()),
  _Scenario('shelf', () => benchmarks.ShelfAppBenchmark().report()),
  _Scenario('dart_http', () => benchmarks.DartHttpAppBenchmark().report()),
];
