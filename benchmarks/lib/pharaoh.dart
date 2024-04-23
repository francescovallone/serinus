import 'package:benchmarks/shared/serinus_benchmark.dart';
import 'package:pharaoh/pharaoh.dart';

class PharaohAppBenchmark extends SerinusBenchmark {

  PharaohAppBenchmark() : super(name: 'Pharaoh');
  
  final app = Pharaoh();

  @override
  Future<void> setup() async {
    app.get('/', (req, res) => res.ok('echo!'));
    await app.listen();
  }

  @override
  Future<void> teardown() async {
    await app.shutdown();
  }

}