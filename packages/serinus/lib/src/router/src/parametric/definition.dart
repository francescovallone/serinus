import '../../../enums/enums.dart';
import '../tree/node.dart';
import '../tree/tree.dart' show ParamAndValue;
import 'utils.dart';

SingleParameterDefn<T> _singleParamDefn<T>(RegExpMatch m) => SingleParameterDefn._(
      m.group(2)!,
      prefix: m.group(1)?.nullIfEmpty,
      suffix: m.group(3)?.nullIfEmpty,
    );

/// Builds a [ParameterDefinition] from the given [part] string.
ParameterDefinition<T> buildParamDefinition<T>(String part) {
  if (closeDoorParametricRegex.hasMatch(part)) {
    throw ArgumentError.value(
        part, null, 'Parameter definition is invalid. Close door neighbors');
  }

  final matches = parametricDefnsRegex.allMatches(part);
  if (matches.isEmpty) {
    throw ArgumentError.value(part, null, 'Parameter definition is invalid');
  }

  if (matches.length == 1) {
    return _singleParamDefn(matches.first);
  }

  return CompositeParameterDefinition._(matches.map(_singleParamDefn));
}

/// Definition of a route parameter.
abstract class ParameterDefinition<T> implements HandlerStore<T> {
  /// The name of the parameter.
  String get name;

  /// The template string representing the parameter.
  String get templateStr;

  /// A unique key for the parameter definition.
  String get key;

  /// Indicates whether this parameter definition is terminal.
  bool get terminal;

  /// Checks if the parameter definition matches the given route.
  bool matches(String route, {bool caseSensitive = false});

  /// Resolves parameters from the given pattern and collects them.
  void resolveParams(String pattern, List<ParamAndValue> collector);
}

/// A single parameter definition with optional prefix and suffix.
class SingleParameterDefn<T> extends ParameterDefinition<T> with HandlerStoreMixin<T> {
  @override
  final String name;

  /// The optional prefix for the parameter.
  final String? prefix;
  /// The optional suffix for the parameter.
  final String? suffix;

  @override
  final String templateStr;

  @override
  String get key => 'prefix=$prefix&suffix=$suffix';

  bool _terminal;

  @override
  bool get terminal => _terminal;

  @override
  bool matches(String route, {bool caseSensitive = false}) {
    final match = matchPattern(route, prefix ?? '', suffix ?? '');
    return match != null;
  }

  SingleParameterDefn._(
    this.name, {
    this.prefix,
    this.suffix,
  })  : templateStr =
            buildTemplateString(name: name, prefix: prefix, suffix: suffix),
        _terminal = false;

  @override
  void resolveParams(final String pattern, List<ParamAndValue> collector) {
    collector.add((
      name: name,
      value: matchPattern(pattern, prefix ?? '', suffix ?? ''),
    ));
  }

  @override
  void addRoute(HttpMethod method, Indexed<T> handler) {
    super.addRoute(method, handler);
    _terminal = true;
  }
}

/// A composite parameter definition made up of multiple single parameter definitions.
class CompositeParameterDefinition<T> extends ParameterDefinition<T>
    implements HandlerStore<T> {
  /// The parts that make up the composite parameter definition.
  final Iterable<SingleParameterDefn<T>> parts;
  final SingleParameterDefn<T> _maybeTerminalPart;

  CompositeParameterDefinition._(this.parts) : _maybeTerminalPart = parts.last;

  @override
  String get templateStr => parts.map((e) => e.templateStr).join();

  @override
  String get name => parts.map((e) => e.name).join('|');

  @override
  String get key => parts.map((e) => e.key).join('|');

  RegExp get _template => buildRegexFromTemplate(templateStr);

  @override
  bool get terminal => _maybeTerminalPart.terminal;

  @override
  bool matches(String route, {bool caseSensitive = false}) =>
      _template.hasMatch(route);

  @override
  void resolveParams(String pattern, List<ParamAndValue> collector) {
    final match = _template.firstMatch(pattern);
    if (match == null) {
      return;
    }

    for (final key in match.groupNames) {
      collector.add((name: key, value: match.namedGroup(key)));
    }
  }

  @override
  void addMiddleware(Indexed<T> handler) {
    _maybeTerminalPart.addMiddleware(handler);
  }

  @override
  void addRoute(HttpMethod method, Indexed<T> handler) {
    _maybeTerminalPart.addRoute(method, handler);
  }

  @override
  void offsetIndex(int index) => _maybeTerminalPart.offsetIndex(index);

  @override
  Indexed<T>? getHandler(HttpMethod method) {
    return _maybeTerminalPart.getHandler(method);
  }

  @override
  bool hasMethod(HttpMethod method) => _maybeTerminalPart.hasMethod(method);

  @override
  Iterable<HttpMethod> get methods => _maybeTerminalPart.methods;
}
