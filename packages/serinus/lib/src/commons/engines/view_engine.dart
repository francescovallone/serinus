abstract class ViewEngine {
  final String viewFolder;

  const ViewEngine({this.viewFolder = 'views'});

  Future<String> render(View view);

  Future<String> renderString(ViewString viewString);
}

class View {
  final String view;
  final Map<String, dynamic> variables;

  View(this.view, this.variables);
}

class ViewString {
  final String viewData;
  final Map<String, dynamic> variables;

  ViewString(this.viewData, this.variables);
}
