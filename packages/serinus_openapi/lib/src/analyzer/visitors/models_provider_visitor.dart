import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';

class ModelProviderInvocationCollector extends RecursiveAstVisitor<void> {
  ModelProviderInvocationCollector(this._typeResolver);

  final InterfaceType? Function(Expression?) _typeResolver;

  final Set<InterfaceElement> providers = {};

  @override
  void visitMethodInvocation(MethodInvocation node) {
    super.visitMethodInvocation(node);
    if (node.methodName.name != 'createApplication') {
      return;
    }
    for (final argument in node.argumentList.arguments) {
      if (argument is NamedExpression &&
          argument.name.label.name == 'modelProvider') {
        final interfaceType = _typeResolver(argument.expression);
        if (interfaceType != null) {
          providers.add(interfaceType.element);
        }
      }
    }
  }
}
