// ignore_for_file: avoid_print

import 'package:openapi_types/openapi_types.dart';
import 'package:serinus_openapi/src/analyzer/analyzer.dart';

Future<void> main() async {
  final analyzer = Analyzer(OpenApiVersion.v3_0);
  final result = await analyzer.analyze();
  for (final entry in result.entries) {
    print('Controller: ${entry.key}');
    var index = 0;
    for (final route in entry.value) {
      print('  Route ${index++}: ${route.exceptions}');
    }
  }
  final entry = result.entries.first;
  var i = 0;
  for (final route in entry.value) {
    print('  Route #${i++}: $route');
    final returnType = route.returnType;
    if (returnType is ResponseObjectV3) {
      print(
        '    Response: ${returnType.content?.map((key, value) => MapEntry(key, value.schema?.toMap()))}',
      );
    }
    final requestBody = route.requestBody;
    if (requestBody != null) {
      print(
        '    Request schema: ${requestBody.schema.toV3(use31: false).toMap()}',
      );
    }
  }
}
