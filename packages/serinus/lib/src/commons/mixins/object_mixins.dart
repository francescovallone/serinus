/// Mixin for objects that can be converted to JSON.
/// 
/// It is mostly used in the [Response] class to convert the data to JSON.
mixin JsonObject {
  Map<String, dynamic> toJson();
}
