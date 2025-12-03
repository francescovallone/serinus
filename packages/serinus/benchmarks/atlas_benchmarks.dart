import 'package:benchmark_harness/perf_benchmark_harness.dart';
import 'package:serinus/serinus.dart';
import 'package:serinus/src/router/atlas.dart';

class AtlasBenchmarks extends PerfBenchmarkBase {
  AtlasBenchmarks(): super('Atlas Lookup Benchmark');

  final atlas = Atlas<int>();

  @override
  void setup() {
    for (var i = 0; i < 1000; i++) {
      atlas.add(HttpMethod.get, '/api/v1/users/$i', i);
      atlas.add(HttpMethod.get, '/api/v1/posts/$i', i + 1000);
      atlas.add(HttpMethod.get, '/api/v2/users/$i', i + 2000);
    }
  }
  
  @override
  void run() {

    final result = atlas.lookup(HttpMethod.get, '/api/v1/users/500');
    if (result.values.first != 500) {
      throw Exception('Benchmark failed: expected 500, got ${result.values.first}');
    }
  }

}

void main() {
  AtlasBenchmarks().report();
}