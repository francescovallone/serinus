import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:benchmarks/shared/serinus_benchmark.dart';

const _defaultRuns = 5;
const _alpha = 0.05;
const _fixedDropThreshold = 0.03; // 3%
const _outputDir = 'benchmarks/results';
const _sqrt2 = 1.4142135623730951; // sqrt(2)

Future<void> main(List<String> arguments) async {
  final runs = _parseIntArg(arguments, '--runs=', fallback: _defaultRuns);
  final runIdArg = _parseStringArg(arguments, '--run-id=');
  final runId = (runIdArg ?? DateTime.now().toUtc().toIso8601String())
      .replaceAll(':', '-');
  final only = _parseListArg(arguments, '--only=');

  final overridesFile = File('pubspec_overrides.yaml');
  final originalOverrides = await _readFileIfExists(overridesFile);

  try {
    // Dev (path override)
    await _writeDevOverride(overridesFile);
    await _pubGet();
    await _runBench(tag: 'dev', runs: runs, runId: runId, only: only);

    // Release (no override, hosted version)
    await _clearOverride(overridesFile);
    await _pubGet();
    await _runBench(tag: 'release', runs: runs, runId: runId, only: only);

    await _compare(runId: runId, only: only);
    await _writeCache(runId: runId, runs: runs, only: only);
  } finally {
    // Restore whatever was there before
    if (originalOverrides != null) {
      await overridesFile.writeAsString(originalOverrides);
    } else if (await overridesFile.exists()) {
      await overridesFile.delete();
    }
  }
}

Future<void> _runBench({
  required String tag,
  required int runs,
  required String runId,
  required List<String> only,
}) async {
  final args = [
    'run',
    'bin/benchmarks.dart',
    '--tag=$tag',
    '--runs=$runs',
    '--run-id=$runId',
    '--output-dir=$_outputDir',
  ];
  if (only.isNotEmpty) {
    args.add('--only=${only.join(',')}');
  }
  final proc = await Process.start('dart', args);
  stdout.addStream(proc.stdout);
  stderr.addStream(proc.stderr);
  final code = await proc.exitCode;
  if (code != 0) {
    throw StateError('Benchmark run failed for $tag (exit code $code)');
  }
}

Future<void> _compare({required String runId, required List<String> only}) async {
  final root = Directory('$_outputDir/serinus/$runId');
  if (!await root.exists()) {
    stdout.writeln('No results found for runId $runId; skipping comparison.');
    return;
  }

  final scenarios = await _collectScenarios(runId: runId, only: only);
  for (final scenario in scenarios) {
    final dev = await _loadScenario(scenario: scenario, runId: runId, tag: 'dev');
    final rel = await _loadScenario(scenario: scenario, runId: runId, tag: 'release');
    if (dev == null || rel == null) {
      stdout.writeln('Missing results for $scenario; skipping.');
      continue;
    }
    final outcome = _regressionCheck(dev, rel);
    _printOutcome(scenario, dev, rel, outcome);
    if (outcome.fail) {
      exitCode = 1;
    }
  }
}

Future<List<String>> _collectScenarios({
  required String runId,
  required List<String> only,
}) async {
  final root = Directory(_outputDir);
  if (!await root.exists()) return [];
  final entries = await root.list().where((e) => e is Directory).toList();
    final names = entries
      .map((e) => e.path.split(Platform.pathSeparator).where((p) => p.isNotEmpty).last)
      .where((e) => e.isNotEmpty)
      .toList();
  final filtered = names.where((n) => only.isEmpty || only.contains(n)).toList();
  return filtered;
}

Future<_StoredScenario?> _loadScenario({
  required String scenario,
  required String runId,
  required String tag,
}) async {
  final file = File('$_outputDir/$scenario/$runId/$tag.json');
  if (!await file.exists()) return null;
  final content = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
  final runs = (content['runs'] as List<dynamic>)
      .map((e) => Result.fromJson(e as Map<String, dynamic>))
      .toList();
  return _StoredScenario(scenario: scenario, tag: tag, samples: runs);
}

class _StoredScenario {
  _StoredScenario({required this.scenario, required this.tag, required this.samples});
  final String scenario;
  final String tag;
  final List<Result> samples;

  double get meanRps => _mean(samples.map((e) => e.rps).toList());
}

class _RegressionOutcome {
  _RegressionOutcome({required this.fail, required this.drop, required this.pValue});
  final bool fail;
  final double drop;
  final double pValue;
}

_RegressionOutcome _regressionCheck(_StoredScenario dev, _StoredScenario release) {
  // Treat release as baseline; regression if dev is slower than release by > threshold.
  final devRps = dev.samples.map((e) => e.rps).toList();
  final relRps = release.samples.map((e) => e.rps).toList();
  final devMean = _mean(devRps);
  final relMean = _mean(relRps);
  final change = relMean == 0 ? 0.0 : (devMean - relMean) / relMean; // negative means slower than release
  final fixedFail = change < -_fixedDropThreshold;
  final pValue = _mannWhitneyP(devRps, relRps);
  final statFail = pValue < _alpha && devMean < relMean;
  return _RegressionOutcome(fail: fixedFail || statFail, drop: change, pValue: pValue);
}

void _printOutcome(String scenario, _StoredScenario dev, _StoredScenario rel, _RegressionOutcome outcome) {
  final dropPerc = (outcome.drop * 100).toStringAsFixed(2);
  stdout.writeln('Scenario: $scenario');
  stdout.writeln('  dev mean rps: ${dev.meanRps.toStringAsFixed(2)}');
  stdout.writeln('  release mean rps: ${rel.meanRps.toStringAsFixed(2)}');
  stdout.writeln('  change vs release: $dropPerc%');
  stdout.writeln('  Mann-Whitney p (two-sided): ${outcome.pValue.toStringAsFixed(4)}');
  stdout.writeln('  status: ${outcome.fail ? 'FAIL' : 'PASS'}');
}

Future<String?> _readFileIfExists(File file) async {
  if (!await file.exists()) return null;
  return file.readAsString();
}

Future<void> _writeDevOverride(File file) async {
  final content = 'dependency_overrides:\n  serinus:\n    path: ../packages/serinus\n';
  await file.writeAsString(content);
}

Future<void> _clearOverride(File file) async {
  if (await file.exists()) {
    await file.delete();
  }
}

Future<void> _pubGet() async {
  final proc = await Process.start('dart', ['pub', 'get']);
  stdout.addStream(proc.stdout);
  stderr.addStream(proc.stderr);
  final code = await proc.exitCode;
  if (code != 0) {
    throw StateError('dart pub get failed (exit code $code)');
  }
}

Future<void> _writeCache({required String runId, required int runs, required List<String> only}) async {
  final dir = Directory('.perf-cache');
  await dir.create(recursive: true);
  final file = File('${dir.path}/latest.json');
  final payload = {
    'runId': runId,
    'runs': runs,
    'only': only,
    'timestamp': DateTime.now().toUtc().toIso8601String(),
  };
  await file.writeAsString(const JsonEncoder.withIndent('  ').convert(payload));
}

int _parseIntArg(List<String> args, String prefix, {required int fallback}) {
  for (final arg in args) {
    if (arg.startsWith(prefix)) {
      return int.tryParse(arg.substring(prefix.length)) ?? fallback;
    }
  }
  return fallback;
}

String? _parseStringArg(List<String> args, String prefix) {
  for (final arg in args) {
    if (arg.startsWith(prefix)) {
      return arg.substring(prefix.length);
    }
  }
  return null;
}

List<String> _parseListArg(List<String> args, String prefix) {
  for (final arg in args) {
    if (arg.startsWith(prefix)) {
      return arg.substring(prefix.length).split(',').where((e) => e.isNotEmpty).toList();
    }
  }
  return [];
}

double _mean(List<double> values) {
  if (values.isEmpty) return 0;
  return values.reduce((a, b) => a + b) / values.length;
}

double _mannWhitneyP(List<double> x, List<double> y) {
  if (x.isEmpty || y.isEmpty) return 1;
  final ranks = <_Ranked>[];
  for (final v in x) {
    ranks.add(_Ranked(value: v, isX: true));
  }
  for (final v in y) {
    ranks.add(_Ranked(value: v, isX: false));
  }
  ranks.sort((a, b) => a.value.compareTo(b.value));

  var i = 0;
  while (i < ranks.length) {
    var j = i + 1;
    while (j < ranks.length && ranks[j].value == ranks[i].value) {
      j++;
    }
    final rankValue = (i + j + 1) / 2.0;
    for (var k = i; k < j; k++) {
      ranks[k] = ranks[k].copyWith(rank: rankValue);
    }
    i = j;
  }

  final n1 = x.length;
  final n2 = y.length;
  final r1 = ranks.where((r) => r.isX).fold<double>(0, (s, r) => s + r.rank);
  final u1 = r1 - n1 * (n1 + 1) / 2.0;
  final u2 = n1 * n2 - u1;
  final u = math.min(u1, u2);
  final mu = n1 * n2 / 2.0;
  final sigma = math.sqrt(n1 * n2 * (n1 + n2 + 1) / 12.0);
  if (sigma == 0) return 1;
  final z = (u - mu) / sigma;
  final p = 2 * (1 - _normalCdf(z.abs()));
  return p;
}

double _normalCdf(double z) {
  return 0.5 * (1 + _erf(z / _sqrt2));
}

// Approximation of the Gaussian error function (Abramowitz-Stegun 7.1.26)
double _erf(double x) {
  const a1 = 0.254829592;
  const a2 = -0.284496736;
  const a3 = 1.421413741;
  const a4 = -1.453152027;
  const a5 = 1.061405429;
  const p = 0.3275911;

  final sign = x < 0 ? -1.0 : 1.0;
  final ax = x.abs();
  final t = 1.0 / (1.0 + p * ax);
  final poly = (((a5 * t + a4) * t + a3) * t + a2) * t + a1;
  final expTerm = math.exp(-ax * ax);
  final y = 1.0 - poly * t * expTerm;
  return sign * y;
}

class _Ranked {
  const _Ranked({required this.value, required this.isX, this.rank = 0});
  final double value;
  final bool isX;
  final double rank;

  _Ranked copyWith({double? rank}) => _Ranked(value: value, isX: isX, rank: rank ?? this.rank);
}