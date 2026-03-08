import 'dart:typed_data';

import '../enums/http_method.dart';
import 'node.dart';

/// Lightweight stack storing start/end coordinates for captured parameters.
final class ParamStack {
  List<int> _coordinates;
  int _length = 0;

  /// Creates a new [ParamStack] with room for [initialCapacity] parameters.
  ParamStack([int initialCapacity = 4])
    : _coordinates = List<int>.filled(initialCapacity * 2, -1, growable: false);

  ParamStack._(this._coordinates, this._length);

  /// Creates an immutable snapshot of the current stack contents.
  factory ParamStack.snapshot(ParamStack stack) {
    final snapshot = Int32List(stack._length);
    for (var i = 0; i < stack._length; i++) {
      snapshot[i] = stack._coordinates[i];
    }
    return ParamStack._(snapshot, stack._length);
  }

  /// The number of parameters currently stored in the stack.
  int get length => _length ~/ 2;

  /// Saves the current stack length for later restoration.
  int save() => _length;

  /// Restores the stack to a previously saved length, effectively discarding any parameters added since then.
  void restore(int value) {
    _length = value;
  }

  /// Pushes a parameter with the given start and end coordinates onto the stack.
  void push(int start, int end) {
    _ensureCapacity(_length + 2);
    _coordinates[_length] = start;
    _coordinates[_length + 1] = end;
    _length += 2;
  }

  /// Pushes a null parameter onto the stack, represented by start and end coordinates of -1.
  void pushNull() => push(-1, -1);

  /// Gets the start coordinate of the parameter at the given index.
  int startAt(int index) => _coordinates[index * 2];

  /// Gets the end coordinate of the parameter at the given index.
  int endAt(int index) => _coordinates[index * 2 + 1];

  void _ensureCapacity(int requiredLength) {
    if (requiredLength <= _coordinates.length) {
      return;
    }
    final expanded = List<int>.filled(requiredLength * 2, -1, growable: false);
    for (var i = 0; i < _length; i++) {
      expanded[i] = _coordinates[i];
    }
    _coordinates = expanded;
  }
}

/// Resume point for iterative Atlas traversal.
final class _Branch<T> {
  final AtlasNode<T> node;
  final int cursor;
  final int paramStackLength;
  final int phase;

  const _Branch({
    required this.node,
    required this.cursor,
    required this.paramStackLength,
    required this.phase,
  });
}

/// Result of a route lookup operation in the Atlas router.
///
/// Contains information about whether a route was found, the handler values,
/// and any extracted parameters from the route path.
abstract class AtlasResult<T> {
  /// The handler values associated with the matched route.
  final List<T> values;

  /// Original lookup path used to materialize parameter values lazily.
  final String? _path;

  /// Ordered parameter names captured by the matched route.
  final List<String> _paramNames;

  /// Start/end coordinates for captured parameter values.
  final ParamStack _paramCoordinates;

  /// Cached computed parameters map.
  Map<String, dynamic>? _paramsCache;

  /// Creates a new [AtlasResult] instance.
  AtlasResult({
    required this.values,
    String? path,
    List<String> paramNames = const [],
    ParamStack? paramCoordinates,
  }) : _path = path,
       _paramNames = paramNames,
       _paramCoordinates = paramCoordinates ?? ParamStack(0);

  /// Parameters extracted from the route, lazily computed and cached.
  Map<String, dynamic> get params {
    if (_paramsCache != null) {
      return _paramsCache!;
    }
    if (_paramNames.isEmpty || _path == null) {
      return _paramsCache = <String, dynamic>{};
    }
    final resolvedParams = <String, dynamic>{};
    for (var i = 0; i < _paramNames.length; i++) {
      final start = _paramCoordinates.startAt(i);
      final end = _paramCoordinates.endAt(i);
      resolvedParams[_paramNames[i]] = start < 0
          ? null
          : _path.substring(start, end);
    }
    return _paramsCache = resolvedParams;
  }

  /// Creates a "not found" result.
  factory AtlasResult.notFound() => NotFoundRoute();

  /// Creates a "method not allowed" result (route exists but no handler for method).
  factory AtlasResult.methodNotAllowed() => MethodNotAllowedRoute();
}

/// Result indicating a successful route match with associated handlers.
final class FoundRoute<T> extends AtlasResult<T> {
  /// Creates a new [FoundRoute] instance.
  FoundRoute({
    required super.values,
    required super.path,
    required super.paramNames,
    required super.paramCoordinates,
  });
}

/// Result indicating that no matching route was found.
final class NotFoundRoute<T> extends AtlasResult<T> {
  /// Creates a new [NotFoundRoute] instance.
  NotFoundRoute() : super(values: const []);
}

/// Result indicating that a route exists but no handler is available for the requested method.
final class MethodNotAllowedRoute<T> extends AtlasResult<T> {
  /// Creates a new [MethodNotAllowedRoute] instance.
  MethodNotAllowedRoute() : super(values: const []);
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
    var currentNode = _root;
    AtlasNode<T>? optionalParent;
    ParamNode<T>? optionalParamNode;
    final pathEnd = _trimmedPathEnd(path);
    var cursor = _isRootPath(path) ? pathEnd : (path.startsWith('/') ? 1 : 0);
    _handlersCache.clear();
    while (cursor < pathEnd) {
      final slashIndex = path.indexOf('/', cursor);
      final segmentEnd = slashIndex == -1 || slashIndex > pathEnd
          ? pathEnd
          : slashIndex;
      final segment = path.substring(cursor, segmentEnd);
      final isLastSegment = segmentEnd >= pathEnd;
      if (segment == TailWildcardNode.key && !isLastSegment) {
        // Tail wildcard must be the last segment
        throw ArgumentError(
          'Tail wildcard "**" must be the last segment in the path "$path".',
        );
      }
      final parentBeforeInsert = currentNode;
      currentNode = _insertSegment(currentNode, segment);

      if (isLastSegment &&
          currentNode is ParamNode<T> &&
          currentNode.optional) {
        optionalParent = parentBeforeInsert;
        optionalParamNode = currentNode;
      }

      cursor = _advanceCursor(segmentEnd, pathEnd);
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
    final params = ParamStack();

    final matchedNode = _matchPath(path, params);

    if (matchedNode == null) {
      return AtlasResult.notFound();
    }

    // Check for handler with specific method or 'all' method
    final handler = matchedNode.handlers[method.index];
    final allHandler = matchedNode.handlers[HttpMethod.all.index];

    final handlers = <T>[];
    if (handler != null) {
      handlers.add(handler);
    }
    if (allHandler != null && handler != allHandler) {
      handlers.add(allHandler);
    }

    if (handlers.isEmpty) {
      // Route exists but no handler for this method
      if (_hasAnyHandler(matchedNode)) {
        return AtlasResult.methodNotAllowed();
      }
      // This should not happen as _matchPath checks for handlers
      return AtlasResult.notFound();
    }
    final result = FoundRoute(
      values: handlers,
      path: path,
      paramNames: matchedNode.parameterNames,
      paramCoordinates: ParamStack.snapshot(params),
    );
    if (matchedNode.parameterNames.isNotEmpty) {
      return result;
    }
    if (_handlersCache.length > 10000) {
      _handlersCache.remove(_handlersCache.keys.first);
    }
    return _handlersCache[cacheKey] ??= result;
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

  bool _isRootPath(String path) {
    return path.isEmpty || path.codeUnits.every((c) => c == 47);
  }

  int _trimmedPathEnd(String path) =>
      path.endsWith('/') ? path.length - 1 : path.length;

  int _advanceCursor(int segmentEnd, int pathEnd) {
    if (segmentEnd >= pathEnd) {
      return pathEnd;
    }
    return segmentEnd + 1;
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

  /// Iteratively matches a path against the tree.
  /// Returns the matched node, or null if no match.
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
  AtlasNode<T>? _matchPath(String path, ParamStack params) {
    final pathEnd = _trimmedPathEnd(path);
    final branches = <_Branch<T>>[];
    final initialCursor = _isRootPath(path)
        ? pathEnd
        : (path.startsWith('/') ? 1 : 0);
    var current = _Branch<T>(
      node: _root,
      cursor: initialCursor,
      paramStackLength: params.save(),
      phase: 0,
    );

    do {
      params.restore(current.paramStackLength);
      final node = current.node;
      final cursor = current.cursor;

      if (cursor >= pathEnd) {
        final optionalParam = node.paramChild;
        if (optionalParam != null &&
            optionalParam.optional &&
            _hasAnyHandler(optionalParam)) {
          params.pushNull();
          return optionalParam;
        }

        if (_hasAnyHandler(node)) {
          return node;
        }

        final tailWildcard = node.tailWildcardChild;
        if (tailWildcard != null && _hasAnyHandler(tailWildcard)) {
          params.push(pathEnd, pathEnd);
          return tailWildcard;
        }

        if (branches.isEmpty) {
          return null;
        }
        current = branches.removeLast();
        continue;
      }

      final slashIndex = path.indexOf('/', cursor);
      final segmentEnd = slashIndex == -1 || slashIndex > pathEnd
          ? pathEnd
          : slashIndex;

      if (current.phase == 0) {
        final staticChild = node.matchStaticSlice(path, cursor, segmentEnd);
        if (staticChild != null) {
          if (node.paramChild != null ||
              node.wildcardChild != null ||
              node.tailWildcardChild != null) {
            branches.add(
              _Branch<T>(
                node: node,
                cursor: cursor,
                paramStackLength: current.paramStackLength,
                phase: 1,
              ),
            );
          }
          current = _Branch<T>(
            node: staticChild,
            cursor: _advanceCursor(segmentEnd, pathEnd),
            paramStackLength: params.save(),
            phase: 0,
          );
          continue;
        }
        current = _Branch<T>(
          node: node,
          cursor: cursor,
          paramStackLength: current.paramStackLength,
          phase: 1,
        );
        continue;
      }

      if (current.phase == 1) {
        final paramNode = node.paramChild;
        if (paramNode != null &&
            _tryPushParamBounds(params, paramNode, path, cursor, segmentEnd)) {
          branches.add(
            _Branch<T>(
              node: node,
              cursor: cursor,
              paramStackLength: current.paramStackLength,
              phase: 2,
            ),
          );
          current = _Branch<T>(
            node: paramNode,
            cursor: _advanceCursor(segmentEnd, pathEnd),
            paramStackLength: params.save(),
            phase: 0,
          );
          continue;
        }
        current = _Branch<T>(
          node: node,
          cursor: cursor,
          paramStackLength: current.paramStackLength,
          phase: 2,
        );
        continue;
      }

      if (current.phase == 2) {
        final paramNode = node.paramChild;
        if (paramNode != null && paramNode.optional) {
          params.pushNull();
          branches.add(
            _Branch<T>(
              node: node,
              cursor: cursor,
              paramStackLength: current.paramStackLength,
              phase: 3,
            ),
          );
          current = _Branch<T>(
            node: paramNode,
            cursor: cursor,
            paramStackLength: params.save(),
            phase: 0,
          );
          continue;
        }
        current = _Branch<T>(
          node: node,
          cursor: cursor,
          paramStackLength: current.paramStackLength,
          phase: 3,
        );
        continue;
      }

      if (current.phase == 3) {
        final wildcardChild = node.wildcardChild;
        if (wildcardChild != null) {
          params.push(cursor, segmentEnd);
          branches.add(
            _Branch<T>(
              node: node,
              cursor: cursor,
              paramStackLength: current.paramStackLength,
              phase: 4,
            ),
          );
          current = _Branch<T>(
            node: wildcardChild,
            cursor: _advanceCursor(segmentEnd, pathEnd),
            paramStackLength: params.save(),
            phase: 0,
          );
          continue;
        }
        current = _Branch<T>(
          node: node,
          cursor: cursor,
          paramStackLength: current.paramStackLength,
          phase: 4,
        );
        continue;
      }

      if (current.phase == 4) {
        final tailWildcardChild = node.tailWildcardChild;
        if (tailWildcardChild != null && _hasAnyHandler(tailWildcardChild)) {
          params.push(cursor, pathEnd);
          return tailWildcardChild;
        }
      }

      if (branches.isEmpty) {
        return null;
      }
      current = branches.removeLast();
    } while (true);
  }

  /// Pushes parameter bounds for a segment, handling prefix and suffix.
  bool _tryPushParamBounds(
    ParamStack stack,
    ParamNode<T> param,
    String path,
    int segmentStart,
    int segmentEnd,
  ) {
    final bounds = param.matchSliceBounds(path, segmentStart, segmentEnd);
    if (bounds == null) {
      return false;
    }

    stack.push(bounds.start, bounds.end);
    return true;
  }
}
