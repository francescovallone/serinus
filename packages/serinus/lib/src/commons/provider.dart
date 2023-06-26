/// SerinusProvider is the base class for all services.
/// 
/// Example:
/// ``` dart
/// class HomeService extends SerinusProvider{
/// // ...
/// }
/// ```
abstract class SerinusProvider{

  const SerinusProvider();
  
  String get name => this.runtimeType.toString();

}