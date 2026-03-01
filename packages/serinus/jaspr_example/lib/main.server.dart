/// The entrypoint for the **server** environment.
///
/// The [main] method will only be executed on the server during pre-rendering.
/// To run code on the client, check the `main.client.dart` file.
library;

import 'package:jaspr/dom.dart';
// Server-specific Jaspr import.
import 'package:jaspr/server.dart';
import 'package:serinus/serinus.dart';

// Imports the [App] component.
import 'app.dart';

// Jaspr ↔ Serinus integration module.
import 'jaspr_serinus.dart';

// This file is generated automatically by Jaspr, do not remove or edit.
import 'main.server.options.dart';

/// Initializes the Serinus server with Jaspr rendering.
///
/// The main() function will be called again during development when hot-reloading.
/// Custom backend implementations must take care of properly managing open http servers
/// and other resources that might be re-created when hot-reloading.
void main() async {
  // Object to resolve async locking of reloads.
  var reloadLock = activeReloadLock = Object();

  // Close any previously running Serinus application (for hot-reload support).
  await activeApp?.close();

  // Create a Serinus application with the Jaspr module and your own modules.
  final app = await serinus.createApplication(
    entrypoint: AppModule(),
    host: '0.0.0.0',
    port: 8080,
  );

  // If the reload lock changed, another reload happened and we should abort.
  if (reloadLock != activeReloadLock) {
    await app.close();
    return;
  }

  activeApp = app;
  await app.serve();
  print('Serving at http://0.0.0.0:8080');
}

// ---------------------------------------------------------------------------
// Application module – wire up your controllers and import JasprModule.
// ---------------------------------------------------------------------------

/// Root module for the application.
///
/// Import [JasprModule] with the root Jaspr component and add your own
/// controllers for API endpoints.
class AppModule extends Module {
  AppModule() : super(
          imports: [
            JasprModule(
              options: defaultServerOptions,
              component: Document(
                title: 'jaspr_example',
                styles: [
                  css.import('https://fonts.googleapis.com/css?family=Roboto'),
                  css('html, body').styles(
                    width: 100.percent,
                    minHeight: 100.vh,
                    padding: .zero,
                    margin: .zero,
                    fontFamily: const .list([FontFamily('Roboto'), FontFamilies.sansSerif]),
                  ),
                  css('h1').styles(
                    margin: .unset,
                    fontSize: 4.rem,
                  ),
                ],
                body: App(),
              ),
            ),
          ],
          controllers: [
            ApiController(),
          ],
        );
}

/// Example API controller – replace with your own logic.
class ApiController extends Controller {
  ApiController() : super('/api') {
    on(Route.get('/'), _hello);
  }

  Future<String> _hello(RequestContext context) async {
    return 'Hello Api';
  }
}

/// Keeps track of the currently running Serinus application.
SerinusApplication? activeApp;

/// Keeps track of the last created reload lock.
Object? activeReloadLock;
