import 'package:jaspr/jaspr.dart';
import 'package:serinus/serinus.dart';

// import 'jaspr_options.dart';

import 'app_module.dart';
import 'jaspr_options.dart';

Future<void> main() async {
  Jaspr.initializeApp(options: defaultJasprOptions, useIsolates: false);
  final app = await serinus.createApplication(
      entrypoint: AppModule(), host: '0.0.0.0', port: 3000);
  await app.serve();
}
