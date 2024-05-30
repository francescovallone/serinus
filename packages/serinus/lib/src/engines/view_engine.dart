/// The abstract class [ViewEngine] is used to define the methods that a view engine must implement.
abstract class ViewEngine {
  /// The folder where the views are stored.
  final String viewFolder;

  /// Constructor for the [ViewEngine] class.
  const ViewEngine({this.viewFolder = 'views'});

  /// This method is used to render a view.
  Future<String> render(View view);

  /// This method is used to render a view from a [String].
  Future<String> renderString(ViewString viewString);
}

/// The class [View] is used to store the view data and the variables that will be used in the view.
class View {
  /// The view data.
  final String view;

  /// The variables that will be used in the view.
  final Map<String, dynamic> variables;

  /// Constructor for the [View] class.
  View(this.view, this.variables);
}

/// The class [ViewString] is used to store the view data and the variables that will be used in the view.
/// It contains the data to be shown as a [String].
class ViewString {
  /// The view data.
  final String viewData;

  /// The variables that will be used in the view.
  final Map<String, dynamic> variables;

  /// Constructor for the [ViewString] class.
  ViewString(this.viewData, this.variables);
}
