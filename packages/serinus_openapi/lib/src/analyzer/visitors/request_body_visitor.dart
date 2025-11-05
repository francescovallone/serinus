import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import '../analyzer.dart';
import '../models.dart';

/// Visitor that collects request body information from method invocations.
class RequestBodyVisitor extends GeneralizingAstVisitor<void> {
  /// Constructor
  RequestBodyVisitor(this._analyzer);

  final Analyzer _analyzer;

  /// The collected request body information.
  RequestBodyInfo? result;

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (result != null) {
      return;
    }
    if (node.methodName.name == 'bodyAs') {
      final typeArguments = node.typeArguments?.arguments;
      if (typeArguments != null && typeArguments.isNotEmpty) {
        final first = typeArguments.first;
        final dartType = first.type;
        final descriptor = _analyzer.schemaFromDartType(dartType);
        if (descriptor != null) {
          final isNullable =
              dartType != null &&
              dartType.nullabilitySuffix == NullabilitySuffix.question;
          result = RequestBodyInfo(
            schema: descriptor,
            contentType: _analyzer.inferContentType(descriptor),
            isRequired: !isNullable,
          );
          return;
        }
      }
    }
    super.visitMethodInvocation(node);
  }
}
