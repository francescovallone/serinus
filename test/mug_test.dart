import 'dart:convert';
import 'dart:io';

import 'package:mug/mug.dart';
import 'package:test/test.dart';

import 'test_module/mug.dart';

void main() {

  MugFactory? mug;
  setUpAll(() async {
    mug = Mug.createApp();
  });

  tearDown(() async {
    await mug!.close();
  });


}
