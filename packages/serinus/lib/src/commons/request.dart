import 'package:serinus/serinus.dart';

import 'internal_request.dart';

class Request {
  final InternalRequest _original;

  final Body? body;

  Request(this._original, {this.params = const {}, this.body}){
    for(final entry in _original.queryParameters.entries){
      switch(entry.value.runtimeType){
        case == int:
          _queryParamters[entry.key] = int.parse(entry.value);
          break;
        case == double:
          _queryParamters[entry.key] = double.parse(entry.value);
          break;
        case == bool:
          _queryParamters[entry.key] = entry.value.toLowerCase() == 'true';
          break;
        default:
          _queryParamters[entry.key] = entry.value;
      }
    }
  }

  final Map<String, dynamic> _queryParamters = {};

  String get path => _original.path;

  String get method => _original.method;

  Map<String, dynamic> get headers => _original.headers;

  Map<String, dynamic> get queryParameters => _queryParamters;

  final Map<String, dynamic> params;

  final Map<String, dynamic> _data = {};

  void addData(String key, dynamic value) {
    _data[key] = value;
  }

  dynamic getData(String key) {
    return _data[key];
  }
}