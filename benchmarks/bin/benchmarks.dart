import 'dart:io';

import 'package:benchmarks/benchmarks.dart' as benchmarks;
import 'package:benchmarks/shared/serinus_benchmark.dart';

Map<String, Result?> results = {};

Future<void> main(List<String> arguments) async {
  results['shelf'] = await benchmarks.ShelfAppBenchmark().report();
  results['serinus'] = await benchmarks.SerinusAppBenchmark().report();
  results['vania (no_cli)'] = await benchmarks.VaniaAppBenchmark().report();
  results['pharaoh'] = await benchmarks.PharaohAppBenchmark().report();
  results['dart_frog (no_cli)'] = await benchmarks.DartFrogAppBenchmark().report();
  await saveToFile();
}

Future<void> saveToFile() async {
  final file = File('all_results.md');
  final lines = [
    ' |                | Req/sec | Trans/sec | Req/sec DIFF | Avg Latency |',
    ' |----------------|---------|-----------|-------------|-----------|'
  ];
  final sorted = Map<String, Result?>.fromEntries(results.entries.toList()..sort((a, b) => a.value!.rps.compareTo(b.value!.rps)));
  for(var entry in sorted.entries){
    if(entry.value == null){
      continue;
    }
    final entryFile = File('${entry.key.split(' ')[0]}_result.md');
    double reqSecDiff = ((entry.value!.rps - sorted.values.first!.rps) / sorted.values.first!.rps) * 100;;
    lines.add(' | ${entry.key} | ${entry.value!.rps} | ${entry.value!.transferRate} | ${reqSecDiff.sign == -1.0 ? '' : '+'}${reqSecDiff.toStringAsFixed(2)}% | ${entry.value?.avgLatency} |');
    final entryLines = [
      '## ${entry.key}',
      '### Requests per second',
      'Requests/sec: ${entry.value!.rps}',
      'Transfer/sec: ${entry.value!.transferRate}',
      'Requests/sec DIFF: ${reqSecDiff.sign == -1.0 ? '' : '+'}${reqSecDiff.toStringAsFixed(2)}%',
      '### Latency',
      'Avg Latency: ${entry.value?.avgLatency}',
      'Stdev Latency: ${entry.value?.stdevLatency}',
      'Max Latency: ${entry.value?.maxLatency}',
      'Stdev Perc: ${entry.value?.stdevPerc}',
      '### Req/Sec',
      'Rps Avg: ${entry.value?.rpsAvg}',
      'Rps Max: ${entry.value?.rpsMax}',
      'Rps Stdev: ${entry.value?.rpdStdev}',
      'Rps Perc: ${entry.value?.rpsPerc}',
    ];
    await entryFile.writeAsString(entryLines.join('\n'));
  }
  await file.writeAsString(lines.join('\n'));
}
