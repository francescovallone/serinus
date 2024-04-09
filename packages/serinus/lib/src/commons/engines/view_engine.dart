import 'dart:async';

abstract class ViewEngine {

  final String viewFolder;

  const ViewEngine({this.viewFolder = 'views'});

  Future<String> render(String view, Map<String, dynamic> data);

  Future<String> renderString(String viewData, Map<String, dynamic> data);

}