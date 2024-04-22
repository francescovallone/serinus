import 'commons/form_data_test.dart';
import 'core/containers/router.dart';
import 'core/contexts.dart';
import 'core/controller.dart';
import 'core/injector/explorer_test.dart';
import 'core/module.dart';
import 'core/provider.dart';
import 'exceptions_test.dart';
import 'http/http.dart';

void main() {
  ControllerTestSuite.runTests();
  ExplorerTestsSuite.runTests();
  ExceptionsTestSuite.runTests();
  ProviderTestSuite.runTests();
  ModuleTestSuite.runTests();
  RouterTestSuite.runTests();
  ContextsTestSuite.runTests();
  HttpTestSuite.runTests();
  FormDataTestSuites.runTests();
}