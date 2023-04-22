
import 'package:serinus/serinus.dart';
import 'package:serinus/src/utils/activator.dart';
import 'package:test/test.dart';

class TestParsableClass extends BodyParsable{

  late String message;

  TestParsableClass.fromJson(Map<String, dynamic> data) : super.fromJson(data){
    message = data["message"];
  }


  @override
  Map<String, dynamic> toJson() {
    return {
      "message": message
    };
  }

}

class TestClass{

  late String message;

  TestClass(){
    message = "Hello world!";
  }
}

void main() {

  test("should instantiate an implementation of BodyParsable because of fromJson named constructor", (){
    var createdInstance = Activator.createInstance(TestParsableClass, {"message": "Hello world!"});
    expect(createdInstance.toJson(), {"message": "Hello world!"});
  });

  test("should instantiate an object using its default constructor", (){
    var createdInstance = Activator.createInstance(TestClass, null);
    expect(createdInstance.message, "Hello world!");
  });

  test("should throw an argument exception because it can't create the instance", (){
    expect(() => Activator.createInstance(int, null), throwsArgumentError);
    
  });

}
