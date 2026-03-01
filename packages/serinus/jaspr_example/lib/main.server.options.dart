// dart format off
// ignore_for_file: type=lint

// GENERATED FILE, DO NOT MODIFY
// Generated with jaspr_builder

import 'package:jaspr/server.dart';
import 'package:jaspr_example/components/counter.dart' as _counter;
import 'package:jaspr_example/components/header.dart' as _header;
import 'package:jaspr_example/pages/about.dart' as _about;
import 'package:jaspr_example/pages/home.dart' as _home;
import 'package:jaspr_example/app.dart' as _app;

/// Default [ServerOptions] for use with your Jaspr project.
///
/// Use this to initialize Jaspr **before** calling [runApp].
///
/// Example:
/// ```dart
/// import 'main.server.options.dart';
///
/// void main() {
///   Jaspr.initializeApp(
///     options: defaultServerOptions,
///   );
///
///   runApp(...);
/// }
/// ```
ServerOptions get defaultServerOptions => ServerOptions(
  clientId: 'main.client.dart.js',
  clients: {
    _about.About: ClientTarget<_about.About>('about'),
    _home.Home: ClientTarget<_home.Home>('home'),
  },
  styles: () => [
    ..._counter.CounterState.styles,
    ..._header.Header.styles,
    ..._about.About.styles,
    ..._app.App.styles,
  ],
);
