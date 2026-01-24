import 'package:benchmark_harness/perf_benchmark_harness.dart';
import 'package:spanner/spanner.dart';

class SpannerBenchmarks extends PerfBenchmarkBase {
  SpannerBenchmarks() : super('Spanner Lookup Benchmark');

  final spanner = Spanner();

  @override
  void setup() {
    for (var i = 0; i < 1000; i++) {
      spanner.addRoute(HTTPMethod.GET, '/api/v1/users/$i', i);
      spanner.addRoute(HTTPMethod.GET, '/api/v1/posts/$i', i + 1000);
      spanner.addRoute(HTTPMethod.GET, '/api/v2/users/$i', i + 2000);
    }
  }

  @override
  void run() {
    final result = spanner.lookup(HTTPMethod.GET, '/api/v1/users/500');
    if (result?.values.first != 500) {
      throw Exception(
        'Benchmark failed: expected 500, got ${result?.values.first}',
      );
    }
  }
}

class SpannerParametricBenchmark extends PerfBenchmarkBase {
  SpannerParametricBenchmark() : super('Spanner Parametric Lookup Benchmark');

  final spanner = Spanner();

  @override
  void setup() {
    spanner.addRoute(HTTPMethod.GET, '/api/v1/users/<id>', 0);
  }

  @override
  void run() {
    final result = spanner.lookup(HTTPMethod.GET, '/api/v1/users/500');
    if (result?.values.firstOrNull != 0) {
      throw Exception(
        'Benchmark failed: expected 0, got ${result?.values.first}',
      );
    }
  }
}

void main() {
  SpannerBenchmarks().report();
  SpannerParametricBenchmark().report();
}
