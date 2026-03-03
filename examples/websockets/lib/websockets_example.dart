import 'package:serinus/serinus.dart';

import 'app_module.dart';

/// The bootstrap function is the entry point of the application.
/// It will be called by the `entrypoint` file in the bin directory.
/// 
/// This function creates a Serinus application using the [AppModule]
/// as the root module, and starts the server on host '0.0.0.0' and port 3000.
Future<void> bootstrap() async {
  final app = await serinus.createApplication(
    entrypoint: AppModule(),
    host: '0.0.0.0',
    port: 3000
  );
  await app.serve();
}
