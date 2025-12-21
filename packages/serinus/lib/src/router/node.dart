import '../enums/http_method.dart';

/// Internal node class for the Atlas radix tree.
///
/// Each node can have:
/// - Static children: exact match paths stored in a map
/// - Parameter child: a single parametric segment
/// - Wildcard child: matches any single segment
/// - Tail wildcard child: matches all remaining segments
/// - Handlers: HTTP method handlers stored in a fixed-size list
class AtlasNode<T> {
  /// Static children stored in a map for O(1) lookup.
  final Map<String, AtlasNode<T>> staticChildren = {};

  /// Handlers for each HTTP method, indexed by method ordinal.
  final List<T?> handlers = List.filled(
    HttpMethod.values.length,
    null,
    growable: false,
  );

  /// The parametric child node, if any.
  ParamNode<T>? paramChild;

  /// The wildcard child node, if any.
  WildcardNode<T>? wildcardChild;

  /// The tail wildcard child node, if any.
  TailWildcardNode<T>? tailWildcardChild;

  /// Gets a child node by its key.
  AtlasNode<T>? getChild(String key) => staticChildren[key];

  /// Adds a child node and returns it.
  ///
  /// Special node types (param, wildcard, tail wildcard) are stored
  /// in their respective properties for quick access.
  AtlasNode<T> addChild(String key, AtlasNode<T> node) {
    switch (node) {
      case TailWildcardNode<T>():
        tailWildcardChild = node;
        staticChildren[key] = node;
        return node;
      case WildcardNode<T>():
        wildcardChild = node;
        staticChildren[key] = node;
        return node;
      case ParamNode<T>():
        paramChild = node;
        staticChildren[key] = node;
        return node;
      default:
        staticChildren[key] = node;
        return node;
    }
  }

  /// Removes a child node by its key.
  void removeChild(String key) {
    final removed = staticChildren.remove(key);
    if (removed == paramChild) {
      paramChild = null;
    }
    if (removed == wildcardChild) {
      wildcardChild = null;
    }
    if (removed == tailWildcardChild) {
      tailWildcardChild = null;
    }
  }
}

/// Sealed class for dynamic segment types.
sealed class DynamicSegment<T> extends AtlasNode<T> {}

/// Parametric segment node that captures a named value from the URL.
///
/// Supports two syntaxes for parameters:
/// - Angle bracket syntax: `<id>`
/// - Colon syntax: `:id`
///
/// Supports optional prefix and suffix for complex patterns (angle bracket only):
/// - `<id>` or `:id` captures the entire segment as `id`
/// - `user_<id>` captures with prefix `user_`
/// - `<name>.json` captures with suffix `.json`
/// - `file_<name>.txt` captures with both prefix and suffix
class ParamNode<T> extends DynamicSegment<T> {
  /// Regex to identify parametric segments using angle bracket syntax: `<id>`
  /// The optional `?` suffix marks the segment as optional.
  static final RegExp angleBracketParamRegExp = RegExp(r'<[^>]+>\??');

  /// Regex to identify parametric segments using colon syntax: `:id`
  /// Matches a colon followed by word characters, not preceded by other word chars.
  /// The optional `?` suffix marks the segment as optional.
  static final RegExp colonParamRegExp = RegExp(r':([\w]+)\??');

  /// Combined regex to identify any parametric segment (either syntax),
  /// including the optional `?` suffix.
  static final RegExp paramRegExp = RegExp(r'(<[^>]+>\??|:[\w]+\??)');

  /// Regex to parse angle bracket parametric segment components.
  ///
  /// Groups:
  /// 1. Prefix (characters before `<`)
  /// 2. Parameter name (inside `<>`)
  /// 3. Suffix (characters after `>`)
  static final RegExp angleBracketDefnsRegExp = RegExp(
    r'([^<]*)<(\w+)>([^<]*)',
  );

  /// Regex to parse colon parametric segment.
  /// Colon params must be the entire segment (no prefix/suffix support).
  ///
  /// Groups:
  /// 1. Parameter name (after `:`)
  static final RegExp colonDefnsRegExp = RegExp(r'^:(\w+)$');

  /// Legacy alias for backwards compatibility.
  static final RegExp paramDefnsRegExp = angleBracketDefnsRegExp;

  /// Optional prefix that must precede the parameter value.
  final String? prefix;

  /// Optional suffix that must follow the parameter value.
  final String? suffix;

  /// The parameter name used as the key in the params map.
  final String name;

  /// Whether this parameter segment is optional (e.g. `<id>?` or `:id?`).
  final bool optional;

  /// Creates a new parametric node.
  ParamNode(this.name, {this.prefix, this.suffix, this.optional = false});
}

/// Wildcard segment that matches any single path segment.
///
/// Example: `/files/*` matches `/files/image.png` but not `/files/a/b`
class WildcardNode<T> extends DynamicSegment<T> {
  /// The key used to represent a wildcard in route definitions.
  static const String key = '*';
}

/// Tail wildcard segment that matches all remaining path segments.
///
/// Example: `/assets/**` matches `/assets/images/logo.png`
///
/// Tail wildcards cannot have children since they consume all remaining segments.
class TailWildcardNode<T> extends DynamicSegment<T> {
  /// The key used to represent a tail wildcard in route definitions.
  static const String key = '**';

  @override
  AtlasNode<T> addChild(String key, AtlasNode<T> node) {
    throw ArgumentError('Tail wildcard segments cannot have children');
  }
}
