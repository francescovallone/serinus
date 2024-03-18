import 'dart:async';

abstract class ViewEngine {

  final String viewFolder;

  const ViewEngine({this.viewFolder = 'views'});

  FutureOr<String> render(String view, Map<String, dynamic> data);

  FutureOr<String> renderString(String viewData, Map<String, dynamic> data);

}