import 'core/controller.dart';
import 'core/injector/explorer_test.dart';
import 'core/provider.dart';
import 'exceptions_test.dart';

void main() {
  ControllerTestSuite.runTests();
  ExplorerTestsSuite.runTests();
  ExceptionsTestSuite.runTests();
  ProviderTestSuite.runTests();
}