
import 'package:serinus/serinus.dart';
import 'package:test/test.dart';

import 'test_module/serinus.dart';

void main() {

  SerinusFactory? serinus;
  setUpAll(() async {
    serinus = Serinus.createControllerSameRouteApp();
  });

  tearDown(() async {
    await serinus?.close();
  });

  test("should throw state error because two controller with the same route", () async {
    expect(() async {
      await serinus?.serve();
    }, throwsStateError);
  });

}
