import 'dart:async';
import 'dart:io';

import 'package:serinus/serinus.dart';

class SimpleModule extends Module {
  SimpleModule() : super(controllers: [], providers: [], middlewares: []);
}

Future<void> main() async {
  final port = 4001;
  final app = await serinus.createApplication(
    entrypoint: SimpleModule(),
    host: InternetAddress.anyIPv4.address,
    port: port,
    logger: ConsoleLogger(prefix: 'ShutdownTest'),
  );

  app.enableShutdownHooks();

  // Start serving in background
  unawaited(app.serve());

  // Give server a moment to start
  await Future.delayed(Duration(seconds: 1));
  print('Server should be listening on port $port');

  // Trigger shutdown
  await Future.delayed(Duration(seconds: 2));
  print('Calling app.close()...');
  await app.close();
  print('app.close() completed');

  // Try to rebind to same port
  try {
    final testServer = await HttpServer.bind(InternetAddress.anyIPv4, port);
    print('Successfully rebound to port $port. Test PASSED');
    await testServer.close(force: true);
  } catch (e, st) {
    print('Failed to bind to port $port after app.close(): $e');
    print(st);
    rethrow;
  }
}
