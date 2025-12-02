import 'package:collection/collection.dart';

import '../../../enums/enums.dart';
import '../parametric/definition.dart';
import '../parametric/utils.dart';

part '../route/action.dart';

sealed class Node<T> with HandlerStoreMixin<T> {
  final Map<String, Node<T>> _nodesMap;

  Node() : _nodesMap = {};

  String get route;

  bool terminal = false;

  Iterable<String> get paths => _nodesMap.keys;

  Iterable<Node<T>> get children => _nodesMap.values;

  bool hasChild(String char) => _nodesMap.containsKey(char);

  Node<T>? getChild(String char) => _nodesMap[char];

  bool get hasChildren => _nodesMap.isNotEmpty;

  ParametricNode<T>? _paramNodecache;
  ParametricNode<T>? get paramNode => _paramNodecache;

  WildcardNode<T>? _wildcardNodeCache;
  WildcardNode<T>? get wildcardNode => _wildcardNodeCache;

  TailWildcardNode<T>? _tailWildcardNodeCache;
  TailWildcardNode<T>? get tailWildcardNode => _tailWildcardNodeCache;

  /// Adds a child node and returns it.
  Node<T> addChild(String key, Node<T> node) {
    if (node is TailWildcardNode<T>) {
      return _tailWildcardNodeCache = node;
    }
    if (node is WildcardNode<T>) {
      return _wildcardNodeCache = node;
    }
    if (node is ParametricNode<T>) {
      return _paramNodecache = node;
    }
    return _nodesMap[key] = node;
  }

  @override
  void addRoute(HttpMethod method, Indexed<T> handler) {
    super.addRoute(method, handler);
    terminal = true;
  }
}

class StaticNode<T> extends Node<T> {
  final String _name;

  StaticNode(this._name);

  @override
  String get route => _name;
}

class ParametricNode<T> extends Node<T> {
  static const String key = '<:>';

  final Map<HttpMethod, List<ParameterDefinition<T>>> _definitionsMap;

  @override
  void addMiddleware(Indexed<T> handler) {
    throw ArgumentError('Parametric Node cannot have middlewares');
  }

  @override
  void addRoute(HttpMethod method, Indexed<T> handler) {
    throw ArgumentError('Parametric Node cannot have routes');
  }

  @override
  Iterable<HttpMethod> get methods => _definitionsMap.keys;

  @override
  Node<T> addChild(String key, Node<T> node) {
    if (node is WildcardNode<T>) {
      throw ArgumentError('Parametric Node cannot have wildcard');
    }
    return super.addChild(key, node);
  }

  List<ParameterDefinition<T>> definitions(HttpMethod method) =>
      _definitionsMap[method] ?? const [];

  ParametricNode(HttpMethod method, ParameterDefinition<T> defn)
      : _definitionsMap = {} {
    addNewDefinition(method, defn, false);
  }

  void addNewDefinition(
    HttpMethod method,
    ParameterDefinition<T> defn,
    bool terminal,
  ) {
    var definitions = _definitionsMap[method];
    if (definitions == null) {
      definitions = [];
      _definitionsMap[method] = definitions;
    }

    if (definitions.isNotEmpty) {
      /// At this point, terminal in [defn] will always be false since
      /// terminals are only set after we've added a route to the definition.
      ///
      /// So we compare key without terminal and then manually check with the
      /// [terminal] value we have right now.
      final existing = definitions.firstWhereOrNull((e) => e.key == defn.key);
      if (existing != null) {
        if (existing.name != defn.name) {
          throw ArgumentError(
            'Route has inconsistent naming in parameter definition\n${[
              ' - ${existing.templateStr}',
              ' - ${defn.templateStr}',
            ].join('\n')}',
          );
        }

        if (existing.terminal && terminal) {
          throw ArgumentError('Route entry already exists');
        }

        return;
      }
    }

    definitions
      ..add(defn)
      ..sortByProps();
  }

  @override
  String get route => ParametricNode.key;

  ParameterDefinition<T>? findMatchingDefinition(
    HttpMethod method,
    String part, {
    bool terminal = false,
  }) {
    return _definitionsMap[method]?.firstWhereOrNull(
      (e) =>
          (!terminal || (e.terminal && e.hasMethod(method))) && e.matches(part),
    );
  }
}

/// A wildcard node that matches any single path segment.
/// Unlike [TailWildcardNode], this node can have children.
class WildcardNode<T> extends StaticNode<T> {
  static const String key = '*';

  WildcardNode() : super(WildcardNode.key);
}

/// A tail wildcard node that matches all remaining path segments.
/// This node cannot have children and is always terminal.
/// When matched, the remaining path is available in the route result.
class TailWildcardNode<T> extends StaticNode<T> {
  static const String key = '**';

  TailWildcardNode() : super(TailWildcardNode.key);

  @override
  bool get terminal => true;

  @override
  Node<T> addChild(String key, Node<T> node) {
    throw ArgumentError('TailWildcard cannot have a child');
  }
}
