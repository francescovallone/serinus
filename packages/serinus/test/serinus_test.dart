
import 'package:serinus/serinus.dart';
import 'package:test/test.dart';

import 'test_module/serinus.dart';

void main() {

  SerinusFactory? serinus;
  setUpAll(() async {
    serinus = Serinus.createApp();
  });

  tearDown(() async {
    await serinus!.close();
  });


}
