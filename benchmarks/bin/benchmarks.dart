import 'package:benchmarks/benchmarks.dart' as benchmarks;

Future<void> main(List<String> arguments) async {
  await benchmarks.ShelfAppBenchmark().report();
  await benchmarks.SerinusAppBenchmark().report();
  await benchmarks.VaniaAppBenchmark().report();
  await benchmarks.PharaohAppBenchmark().report();
}
