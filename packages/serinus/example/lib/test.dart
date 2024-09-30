class TestObject {

  TestObject();

  static TestObject fromRequest(Map<String, dynamic> request) {
    return TestObject();
  }

  Map<String, dynamic> toBody() {
    return {};
  }

}