import 'dart:async';
import 'dart:convert';

import 'package:mug/mug.dart';

import 'app_module.dart';

void main(List<String> arguments) {
  MugFactory application = MugFactory.createApp(AppModule());
  application.serve();
}
