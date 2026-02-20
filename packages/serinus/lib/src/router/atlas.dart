import '../enums/http_method.dart';
import 'node.dart';

/// A record type representing a parameter name and its corresponding value.
typedef ParamAndValue = ({String name, String? value});

/// Result of a route lookup operation in the Atlas router.
///
/// Contains information about whether a route was found, the handler values,
/// and any extracted parameters from the route path.
abstract class AtlasResult<T> {
  /// The handler values associated with the matched route.
  final List<T> values;

  /// Raw parameters extracted from the route path.
  final List<ParamAndValue> _rawParams;

  /// Cached computed parameters map.
  Map<String, dynamic>? _paramsCache;

  /// Creates a new [AtlasResult] instance.
  AtlasResult({required this.values, required List<ParamAndValue> rawParams})
    : _rawParams = rawParams;

  /// Parameters extracted from the route, lazily computed and cached.
  Map<String, dynamic> get params {
    if (_paramsCache != null) {
      return _paramsCache!;
    }
    _paramsCache = <String, dynamic>{};
    for (final (:name, :value) in _rawParams) {
      _paramsCache![name] = value;
    }
    return _paramsCache!;
  }

  /// Creates a "not found" result.
  factory AtlasResult.notFound() => NotFoundRoute();

  /// Creates a "method not allowed" result (route exists but no handler for method).
  factory AtlasResult.methodNotAllowed() => MethodNotAllowedRoute();
}

/// Result indicating a successful route match with associated handlers.
final class FoundRoute<T> extends AtlasResult<T> {
  /// Creates a new [FoundRoute] instance.
  FoundRoute({required super.values, required super.rawParams});
}

/// Result indicating that no matching route was found.
final class NotFoundRoute<T> extends AtlasResult<T> {
  /// Creates a new [NotFoundRoute] instance.
  NotFoundRoute() : super(values: const [], rawParams: const []);
}

/// Result indicating that a route exists but no handler is available for the requested method.
final class MethodNotAllowedRoute<T> extends AtlasResult<T> {
  /// Creates a new [MethodNotAllowedRoute] instance.
  MethodNotAllowedRoute() : super(values: const [], rawParams: const []);
}

/// Atlas is a high-performance Generic HTTP Router implementation.
///
/// It uses a Radix Tree (compact Prefix Tree) internally for efficient
/// route matching with O(k) complexity where k is the length of the path.
///
/// ## Features
/// - **Route Parameters**: `/users/<id>` or `/users/:id` captures `id` from the URL
/// - **Wildcards**: `/files/*` matches any single segment
/// - **Tail Wildcards**: `/assets/**` matches any number of remaining segments
/// - **Prefix/Suffix Parameters**: `/files/<name>.json` captures `name` with `.json` suffix
///
/// ## Example
/// ```dart
/// final router = Atlas<Handler>();
///
/// router.add(HttpMethod.get, '/users/<id>', userHandler);
/// router.add(HttpMethod.get, '/posts/:postId', postHandler);  // colon syntax
/// router.add(HttpMethod.get, '/files/*', fileHandler);
/// router.add(HttpMethod.get, '/assets/**', assetHandler);
///
/// final result = router.lookup(HttpMethod.get, '/users/123');
/// print(result.params); // {id: '123'}
/// ```
final class Atlas<T> {
  /// The root node of the radix tree.
  late final AtlasNode<T> _root;

  /// Creates a new [Atlas] router instance.
  Atlas() {
    _root = AtlasNode<T>();
  }

  /// Adds a route to the router with the given [method], [path], and [handler].
  ///
  /// The path can contain:
  /// - Static segments: `/users/list`
  /// - Parameters: `/users/<id>`
  /// - Parameters with prefix/suffix: `/files/<name>.json`
  /// - Optional parameters: `/users/<id>?` or `/users/:id?`
  /// - Wildcards: `/files/*`
  /// - Tail wildcards: `/assets/**`
  ///
  /// Returns `true` if the route was added successfully.
  bool add(HttpMethod method, String path, T handler) {
    final segments = _parsePathSegments(path);
    var currentNode = _root;
    AtlasNode<T>? optionalParent;
    ParamNode<T>? optionalParamNode;
    _handlersCache.clear();
    for (var i = 0; i < segments.length; i++) {
      final segment = segments[i];
      if (segment == TailWildcardNode.key && i != segments.length - 1) {
        // Tail wildcard must be the last segment
        throw ArgumentError(
          'Tail wildcard "**" must be the last segment in the path "$path".',
        );
      }
      final parentBeforeInsert = currentNode;
      currentNode = _insertSegment(currentNode, segment);

      final isLastSegment = i == segments.length - 1;
      if (isLastSegment &&
          currentNode is ParamNode<T> &&
          currentNode.optional) {
        optionalParent = parentBeforeInsert;
        optionalParamNode = currentNode;
      }
    }

    // When the last segment is optional we register the handler on the
    // param node and on its parent to allow matching with and without
    // the optional segment.
    if (optionalParent != null && optionalParamNode != null) {
      if (_conflictsWithOptional(optionalParent, method)) {
        throw ArgumentError(
          'Conflicting optional route "$path": a route without the optional '
          'segment is already registered.',
        );
      }
      if (_conflictsWithOptional(optionalParamNode, method)) {
        throw ArgumentError(
          'Route "$path" with method ${method.toString()} is already registered.',
        );
      }

      optionalParamNode.handlers[method.index] = handler;
      optionalParent.handlers[method.index] = handler;
      return true;
    }

    // Guard against registering a static route that conflicts with an
    // existing optional parameter route at the same level.
    final optionalChild = currentNode.paramChild;
    if (optionalChild != null &&
        optionalChild.optional &&
        _conflictsWithOptional(optionalChild, method)) {
      throw ArgumentError(
        'Conflicting route "$path": an optional parameter route already '
        'handles this path.',
      );
    }

    if (_hasHandlerConflict(currentNode, method)) {
      throw ArgumentError(
        'Route "$path" with method ${method.toString()} is already registered.',
      );
    }

    currentNode.handlers[method.index] = handler;
    return true;
  }

  final _handlersCache = <(int, String), AtlasResult<T>>{};

  /// Looks up a route matching the given [method] and [path].
  ///
  /// Returns an [AtlasResult] containing:
  /// - `routeExists`: Whether any route matches the path
  /// - `hasHandler`: Whether a handler exists for the specific method
  /// - `values`: List of matching handlers
  /// - `params`: Map of extracted parameters
  @pragma('vm:prefer-inline')
  AtlasResult<T> lookup(HttpMethod method, String path) {
    final cacheKey = (method.index, path);
    if (_handlersCache.containsKey(cacheKey)) {
      return _handlersCache[cacheKey]!;
    }
    final segments = _parsePathSegments(path);
    final params = <ParamAndValue>[];

    final matchResult = _matchPath(_root, segments, 0, params, method);

    if (matchResult == null) {
      return AtlasResult.notFound();
    }

    final (node, extractedParams) = matchResult;

    // Check for handler with specific method or 'all' method
    final handler = node.handlers[method.index];
    final allHandler = node.handlers[HttpMethod.all.index];

    final handlers = <T>[];
    if (handler != null) {
      handlers.add(handler);
    }
    if (allHandler != null && handler != allHandler) {
      handlers.add(allHandler);
    }

    if (handlers.isEmpty) {
      // Route exists but no handler for this method
      if (_hasAnyHandler(node)) {
        return AtlasResult.methodNotAllowed();
      }
      // This should not happen as _matchPath checks for handlers
      return AtlasResult.notFound();
    }
    if (_handlersCache.length > 10000) {
      _handlersCache.remove(_handlersCache.keys.first);
    }
    return _handlersCache[cacheKey] ??= FoundRoute(
      values: handlers,
      rawParams: extractedParams,
    );
  }

  /// Checks if a node has any handler registered.
  @pragma('vm:prefer-inline')
  bool _hasAnyHandler(AtlasNode<T> node) {
    for (final handler in node.handlers) {
      if (handler != null) {
        return true;
      }
    }
    return false;
  }

  /// Returns true when the exact [method] is already registered on [node].
  @pragma('vm:prefer-inline')
  bool _hasHandlerConflict(AtlasNode<T> node, HttpMethod method) {
    if (method == HttpMethod.all) {
      return node.handlers[HttpMethod.all.index] != null;
    }
    return node.handlers[method.index] != null;
  }

  /// Returns true when an optional route would overlap an existing handler.
  ///
  /// This treats `all` as a conflict for any specific method.
  @pragma('vm:prefer-inline')
  bool _conflictsWithOptional(AtlasNode<T> node, HttpMethod method) {
    if (method == HttpMethod.all) {
      return _hasAnyHandler(node);
    }
    return node.handlers[method.index] != null ||
        node.handlers[HttpMethod.all.index] != null;
  }

  final _pathsCache = <String, List<String>>{};

  /// Parses a path string into segments.
  List<String> _parsePathSegments(String path) {
    if (_pathsCache.containsKey(path)) {
      return _pathsCache[path]!;
    }
    if (_pathsCache.length > 10000) {
      _pathsCache.remove(_pathsCache.keys.first);
    }
    if (path.isEmpty || path == '/') {
      return const <String>[];
    }
    if (path.codeUnits.every((c) => c == 47)) {
      return const <String>[];
    }
    final start = path.startsWith('/') ? 1 : 0;
    final end = path.endsWith('/') ? path.length - 1 : path.length;
    final segments = path.substring(start, end).split('/');
    return _pathsCache[path] = segments;
  }

  /// Inserts a segment into the tree, creating appropriate node types.
  ///
  /// Throws [ArgumentError] if attempting to add a conflicting parametric segment
  /// (e.g., adding `:id` when `<id>` already exists at the same level).
  AtlasNode<T> _insertSegment(AtlasNode<T> parent, String segment) {
    // Check for existing child with same key
    final existingChild = parent.getChild(segment);
    if (existingChild != null) {
      return existingChild;
    }

    // Check if this is a parametric segment
    final isParamSegment = ParamNode.paramRegExp.hasMatch(segment);

    // If adding a param segment, check for existing param child conflict
    if (isParamSegment && parent.paramChild != null) {
      throw ArgumentError(
        'Conflicting parametric route: cannot add "$segment" because a '
        'parametric segment "${parent.paramChild!.name}" already exists at this level. '
        'Routes like "/data/:id" and "/data/<id>" conflict with each other.',
      );
    }

    // Create new node based on segment type
    final newNode = _createNodeForSegment(segment);
    return parent.addChild(segment, newNode);
  }

  /// Creates the appropriate node type for a segment.
  AtlasNode<T> _createNodeForSegment(String segment) {
    if (segment == TailWildcardNode.key) {
      return TailWildcardNode<T>();
    } else if (segment == WildcardNode.key) {
      return WildcardNode<T>();
    } else if (ParamNode.paramRegExp.hasMatch(segment)) {
      return _parseParamSegment(segment);
    }
    return AtlasNode<T>();
  }

  /// Parses a parametric segment and creates the appropriate node.
  ///
  /// Supports two syntaxes:
  /// - Angle bracket: `<id>`, `prefix_<id>`, `<id>.suffix`
  /// - Colon: `:id` (no prefix/suffix support)
  ParamNode<T> _parseParamSegment(String segment) {
    final isOptional = segment.endsWith('?');
    final normalizedSegment = isOptional
        ? segment.substring(0, segment.length - 1)
        : segment;

    // Try colon syntax first (simpler, must be entire segment)
    final colonMatch = ParamNode.colonDefnsRegExp.firstMatch(normalizedSegment);
    if (colonMatch != null) {
      return ParamNode<T>(colonMatch.group(1)!, optional: isOptional);
    }

    // Try angle bracket syntax (supports prefix/suffix)
    final angleBracketMatch = ParamNode.angleBracketDefnsRegExp.firstMatch(
      normalizedSegment,
    );
    if (angleBracketMatch != null) {
      final prefix = angleBracketMatch.group(1);
      final name = angleBracketMatch.group(2)!;
      final suffix = angleBracketMatch.group(3);
      return ParamNode<T>(
        name,
        prefix: prefix?.isNotEmpty == true ? prefix : null,
        suffix: suffix?.isNotEmpty == true ? suffix : null,
        optional: isOptional,
      );
    }

    throw ArgumentError.value(
      segment,
      'segment',
      'Invalid parametric segment format. Use <name> or :name syntax.',
    );
  }

  /// Recursively matches a path against the tree.
  /// Returns the matched node and extracted parameters, or null if no match.
  ///
  /// Matching priority:
  /// 1. Static/literal matches (highest priority)
  /// 2. Parametric matches
  /// 3. Wildcard matches
  /// 4. Tail wildcard matches (lowest priority)
  ///
  /// The algorithm backtracks when a partial match fails, trying lower priority
  /// alternatives to ensure the most specific route is found. A match is only
  /// considered successful if the final node has at least one handler.
  (AtlasNode<T>, List<ParamAndValue>)? _matchPath(
    AtlasNode<T> node,
    List<String> segments,
    int index,
    List<ParamAndValue> params,
    HttpMethod method,
  ) {
    // Base case: all segments consumed
    if (index >= segments.length) {
      final optionalParam = node.paramChild;
      if (optionalParam != null &&
          optionalParam.optional &&
          _hasAnyHandler(optionalParam)) {
        final newParams = List<ParamAndValue>.from(params)
          ..add((name: optionalParam.name, value: null));
        return (optionalParam, newParams);
      }

      // Only return this node if it has at least one handler
      // This enables backtracking when a path matches structurally but has no handler
      if (_hasAnyHandler(node)) {
        return (node, params);
      }
      return null;
    }

    final segment = segments[index];

    final staticChild = node.getChild(segment);
    if (staticChild != null) {
      final result = _matchPath(
        staticChild,
        segments,
        index + 1,
        params,
        method,
      );
      if (result != null) {
        return result;
      }
    }

    if (node.paramChild != null) {
      final paramNode = node.paramChild!;
      final paramValue = _extractParamValue(paramNode, segment);
      if (paramValue != null) {
        final newParams = List<ParamAndValue>.from(params)
          ..add((name: paramNode.name, value: paramValue));
        final result = _matchPath(
          paramNode,
          segments,
          index + 1,
          newParams,
          method,
        );
        if (result != null) {
          return result;
        }
        // If parametric match path failed, continue to try wildcard alternatives
      }

      if (paramNode.optional) {
        final optionalParams = List<ParamAndValue>.from(params)
          ..add((name: paramNode.name, value: null));
        final optionalResult = _matchPath(
          paramNode,
          segments,
          index,
          optionalParams,
          method,
        );
        if (optionalResult != null) {
          return optionalResult;
        }
      }
    }

    if (node.wildcardChild != null) {
      final newParams = List<ParamAndValue>.from(params)
        ..add((name: '*', value: segment));
      final result = _matchPath(
        node.wildcardChild!,
        segments,
        index + 1,
        newParams,
        method,
      );
      if (result != null) {
        return result;
      }
      // If wildcard match path failed, continue to try tail wildcard
    }

    if (node.tailWildcardChild != null) {
      final remainingPath = segments.sublist(index).join('/');
      final newParams = List<ParamAndValue>.from(params)
        ..add((name: '**', value: remainingPath));
      // Tail wildcard always consumes remaining segments, so check for handler
      if (_hasAnyHandler(node.tailWildcardChild!)) {
        return (node.tailWildcardChild!, newParams);
      }
    }

    return null;
  }

  /// Extracts the parameter value from a segment, handling prefix/suffix.
  String? _extractParamValue(ParamNode<T> param, String segment) {
    final prefix = param.prefix;
    final suffix = param.suffix;

    if (prefix != null && !segment.startsWith(prefix)) {
      return null;
    }
    if (suffix != null && !segment.endsWith(suffix)) {
      return null;
    }

    final startIndex = prefix?.length ?? 0;
    final endIndex = suffix != null
        ? segment.length - suffix.length
        : segment.length;

    if (startIndex >= endIndex) {
      return null;
    }

    return segment.substring(startIndex, endIndex);
  }
}
