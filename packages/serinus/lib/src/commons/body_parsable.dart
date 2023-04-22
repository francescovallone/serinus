/// BodyParsable is an abstract class that can be used to parse a json body
/// into a class. It has two methods that must be implemented:
/// - [BodyParsable.fromJson] to parse the json body into the class
/// - [toJson] to convert the class into a json body
/// 
/// Example:
/// ``` dart
/// class User extends BodyParsable{
///  late String name;
///  late String email;
/// 
///  User(this.name, this.email);
/// 
///  @override
///  User.fromJson(Map<String, dynamic> data) : super.fromJson(data){
///     name = data['name'];
///     email = data['email']; 
///  }
/// 
///   @override
///  Map<String, dynamic> toJson() => {
///    'name': name,
///    'email': email,
///  };
/// }
abstract class BodyParsable{

  BodyParsable.fromJson(Map<String, dynamic> data);

  Map<String, dynamic> toJson();

}