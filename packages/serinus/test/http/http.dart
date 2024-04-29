import 'responses_test.dart';
import 'session_test.dart';

class HttpTestSuite {

  static void runTests(){
    ResponsesTestSuite.runTests();
    SessionsTestSuite.runTests();
  }

}