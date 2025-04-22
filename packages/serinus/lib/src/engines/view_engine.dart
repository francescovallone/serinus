/// The abstract class [ViewEngine] is used to define the methods that a view engine must implement.
abstract class ViewEngine {
  /// The folder where the views are stored.
  final String viewFolder;

  /// Constructor for the [ViewEngine] class.
  const ViewEngine({this.viewFolder = 'views'});

  /// This method is used to render a view.
  Future<String> render(View view);

}

/// The [View] class contains all the information needed to render a view by a view engine.
class View {

  /// The view data.
  final String template;

  /// The variables that will be used in the view.
  final Map<String, dynamic> variables;

  /// Boolean value to indicate if the view is a template.
  final bool fromFile;

  /// Constructor for the [View] class.
  const View._(this.template, this.variables, this.fromFile);

  /// Constructor for the [View] class with a template file.
  factory View.template(String template, Map<String, dynamic> variables) {
    return View._(template, variables, true);
  }

  /// Constructor for the [View] class with a template string.
  factory View.string(String template, Map<String, dynamic> variables) {
    return View._(template, variables, false);
  }

}
