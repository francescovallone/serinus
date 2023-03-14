import 'package:mug/mug.dart';
import 'package:test/test.dart';

import 'test_module/mug.dart';

void main() {

  MugFactory? mug;
  MugFactory? mugControllerWrong;
  setUpAll(() async {
    mug = Mug.createApp();
    mugControllerWrong = Mug.createControllerWrongApp();
  });

  tearDown(() async {
    await mug?.close();
  });

  tearDownAll(() async {
    await mugControllerWrong?.close();
  });

  test('should throw exception when controller without decorator', () async {
    expect(() async {
      await mugControllerWrong?.serve();
    }, throwsStateError);
  });

  
}
