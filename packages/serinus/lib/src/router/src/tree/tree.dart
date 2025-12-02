import 'package:meta/meta.dart';

import '../../../enums/enums.dart';
import '../parametric/definition.dart';
import '../parametric/utils.dart';
import 'node.dart';

/// A record type representing a parameter name and its corresponding value.
typedef ParamAndValue = ({String name, String? value});

/// The base path used for routing.
const basePath = '/';

/// A class representing the routing atlas, which manages the routing tree.
class Atlas<T> {
  late final Node<T> _root;

  /// The root node of the routing tree.
  Node<T> get root => _root;

  int _currentIndex = 0;

  int get _nextIndex => _currentIndex + 1;

  /// Cache for lookup results - avoids repeated type checks on hot paths
  final _lookupCache = <(HttpMethod, String), RouteResult<T>?>{};

  /// Creates an instance of [Atlas].
  Atlas() : _root = StaticNode(basePath);

  /// Adds a route with the specified [method], [path], and [handler].
  void add(HttpMethod method, String path, T handler) {
    _on(method, path).addRoute(method, (
      index: _nextIndex,
      value: handler,
    ));
    _lookupCache.clear();
    _currentIndex = _nextIndex;
  }

  /// Adds middleware for the specified [path] with the given [handler].
  void addMiddleware(String path, T handler) {
    _on(HttpMethod.all, path).addMiddleware((
      index: _nextIndex,
      value: handler,
    ));
    _lookupCache.clear();
    _currentIndex = _nextIndex;
  }

  /// Attaches a node to the routing tree at the specified [path].
  void attachNode(String path, Node<T> node) {
    final pathSegments = getRoutePathSegments(path);
    if (pathSegments.isEmpty) {
      root.addChild(basePath, node);
    }

    Node<T> rootNode = root;

    final totalLength = pathSegments.length;
    for (int i = 0; i < totalLength; i++) {
      final routePart = pathSegments[i];
      final isLastPart = i == totalLength - 1;

      final maybeChild = rootNode.getChild(routePart);
      if (isLastPart) {
        if (maybeChild != null) {
          throw ArgumentError.value(path, null, 'Route entry already exists');
        }

        rootNode = rootNode.addChild(
          routePart,
          node..offsetIndex(_currentIndex),
        );

        _currentIndex = _nextIndex;
        break;
      }

      if (maybeChild == null) {
        rootNode = rootNode.addChild(routePart, StaticNode(routePart));
      }
    }
  }

  HandlerStore<T> _on(HttpMethod method, String path) {
    final parts = getRoutePathSegments(path);
    Node<T> rootNode = _root;

    if (parts.isEmpty) {
      return rootNode;
    }

    if (parts[0] == TailWildcardNode.key) {
      return rootNode.tailWildcardNode ??
          rootNode.addChild(TailWildcardNode.key, TailWildcardNode());
    }

    if (parts[0] == WildcardNode.key) {
      return rootNode.wildcardNode ??
          rootNode.addChild(WildcardNode.key, WildcardNode());
    }

    for (int index = 0; index < parts.length; index++) {
      final result = Atlas._computeNode(
        rootNode,
        method,
        index,
        parts: parts,
      );

      if (result is! Node<T>) {
        return result;
      }
      rootNode = result;
    }

    return rootNode;
  }

  /// Given the current segment in a route, this method figures
  /// out which node to create as a child to the current root node [node]
  ///
  /// TLDR -> we figure out which node to create and when we find or create that node,
  /// it then becomes our root node.
  ///
  /// - eg1: when given `users` in `/users`
  /// we will attempt searching for a child, if not found, will create
  /// a new [StaticNode] on the current root [node] and then return that.
  ///
  ///- eg2: when given `<userId>` in `/users/<userId>`
  /// we will find a static child `users` or create one, then proceed to search
  /// for a [ParametricNode] on the current root [node]. If found, we fill add a new
  /// definition, or create a new [ParametricNode] with this definition.
  static HandlerStore<T> _computeNode<T>(
    Node<T> node,
    HttpMethod method,
    int index, {
    required List<String> parts,
  }) {
    final routePart = parts[index];
    final nextPart = parts.elementAtOrNull(index + 1);
    final part = routePart;
    final child = node.getChild(part);
    if (child != null) {
      return node.addChild(part, child);
    } else if (part.isStatic) {
      return node.addChild(part, StaticNode(part));
    } else if (part.isTailWildCard) {
      if (nextPart != null) {
        throw ArgumentError.value(
          parts.join('/'),
          null,
          'Route definition is not valid. TailWildcard (**) must be the end of the route',
        );
      }
      return node.addChild(TailWildcardNode.key, TailWildcardNode());
    } else if (part.isWildCard) {
      // Single segment wildcard (*) can have children
      final wildcardNode = node.wildcardNode ?? WildcardNode<T>();
      return node.addChild(WildcardNode.key, wildcardNode);
    }

    final defn = buildParamDefinition<T>(routePart);
    final paramNode = node.paramNode;

    if (paramNode == null) {
      final newNode = node.addChild(
        ParametricNode.key,
        ParametricNode(method, defn),
      );
      return nextPart == null ? defn : newNode;
    }

    paramNode.addNewDefinition(method, defn, nextPart == null);

    return nextPart == null
        ? defn
        : node.addChild(ParametricNode.key, paramNode);
  }

  @pragma('vm:prefer-inline')
  /// Looks up a route for the given [method] and [route] string.
  RouteResult<T> lookup(HttpMethod method, String route) {
    // Check cache first
    final cacheKey = (method, route);
    final cached = _lookupCache[cacheKey];
    if (cached != null) {
      return cached;
    }

    final result = _lookupInternal(method, route);
    _lookupCache[cacheKey] = result;
    return result;
  }

  RouteResult<T> _lookupInternal(HttpMethod method, String route) {
    final pathSegments = getRoutePathSegments(route);
    final rootMiddlewares = root.middlewares;
    final resolvedParams = <ParamAndValue>[];
    final resolvedHandlers = <Indexed<T>>[];
    
    // Add root middlewares
    final rootMiddlewaresLength = rootMiddlewares.length;
    for (int i = 0; i < rootMiddlewaresLength; i++) {
      resolvedHandlers.add(rootMiddlewares[i]);
    }

    @pragma('vm:prefer-inline')
    List<Indexed<T>> getResults(Indexed<T>? handler) =>
        handler != null ? (resolvedHandlers..add(handler)) : resolvedHandlers;

    if (pathSegments.isEmpty) {
      final handler = _root.getHandler(method);
      return RouteResult(
        resolvedParams,
        getResults(handler),
        routeExists: true,
        hasHandler: handler != null,
      );
    }

    final segmentsLength = pathSegments.length;
    Node<T> rootNode = _root;

    /// Keep track of last tail wildcard we encounter along route.
    /// We'll resort to this if we don't find the route we were looking for.
    TailWildcardNode<T>? tailWildcardNode = rootNode.tailWildcardNode;
    int tailWildcardIndex = 0;
    
    /// Keep track of last single-segment wildcard
    WildcardNode<T>? wildcardNode = rootNode.wildcardNode;

    for (int i = 0; i < segmentsLength; i++) {
      final currPart = pathSegments[i];
      final isLastPart = i == (segmentsLength - 1);

      final parametricNode = rootNode.paramNode;
      final childNode = rootNode.getChild(currPart) ??
          parametricNode?.getChild(currPart);

      if (childNode is StaticNode<T> && isLastPart) {
        rootNode = childNode;
        break;
      }

      // Update tail wildcard tracking
      final nodeTailWildcard = childNode?.tailWildcardNode ?? rootNode.tailWildcardNode;
      if (nodeTailWildcard != null) {
        tailWildcardNode = nodeTailWildcard;
        tailWildcardIndex = i;
      }

      // Update single-segment wildcard tracking
      final nodeWildcard = childNode?.wildcardNode ?? rootNode.wildcardNode;
      if (nodeWildcard != null) {
        wildcardNode = nodeWildcard;
      }

      if (childNode == null && parametricNode == null) {
        // Try tail wildcard first (captures all remaining)
        if (tailWildcardNode != null) {
          final tailSegments = pathSegments.sublist(tailWildcardIndex);
          final tail = tailSegments.join('/');
          final handler = tailWildcardNode.getHandler(method);
          return RouteResult(
            resolvedParams,
            getResults(handler),
            routeExists: true,
            hasHandler: handler != null,
            actual: tailWildcardNode,
            tail: tail,
          );
        }
        
        // Try single-segment wildcard (only if this is the last segment)
        if (wildcardNode != null && isLastPart) {
          rootNode = wildcardNode;
          break;
        }

        return RouteResult(
          resolvedParams,
          getResults(null),
          routeExists: false,
          hasHandler: false,
        );
      }

      rootNode = (childNode ?? parametricNode)!;

      final definition = parametricNode?.findMatchingDefinition(
        method,
        currPart,
        terminal: isLastPart,
      );

      /// If we don't find a matching path or a matching definition, then
      /// use wildcard if we have any registered
      if (childNode == null && definition == null) {
        // Try tail wildcard first
        if (tailWildcardNode != null) {
          final tailSegments = pathSegments.sublist(tailWildcardIndex);
          final tail = tailSegments.join('/');
          final handler = tailWildcardNode.getHandler(method);
          return RouteResult(
            resolvedParams,
            getResults(handler),
            routeExists: true,
            hasHandler: handler != null,
            actual: tailWildcardNode,
            tail: tail,
          );
        }
        
        if (wildcardNode != null) {
          rootNode = wildcardNode;
        }
        break;
      }

      if (childNode != null) {
        final childMiddlewares = childNode.middlewares;
        final childMiddlewaresLength = childMiddlewares.length;
        for (int j = 0; j < childMiddlewaresLength; j++) {
          resolvedHandlers.add(childMiddlewares[j]);
        }
        continue;
      }

      definition!.resolveParams(currPart, resolvedParams);

      if (isLastPart && definition.terminal) {
        final handler = definition.getHandler(method);
        return RouteResult(
          resolvedParams,
          getResults(handler),
          routeExists: true,
          hasHandler: handler != null,
          actual: definition,
        );
      }
    }

    final nodeMiddlewares = rootNode.middlewares;
    final nodeMiddlewaresLength = nodeMiddlewares.length;
    for (int j = 0; j < nodeMiddlewaresLength; j++) {
      resolvedHandlers.add(nodeMiddlewares[j]);
    }
    
    // Check if this is a tail wildcard node
    if (rootNode is TailWildcardNode<T>) {
      final handler = rootNode.getHandler(method);
      return RouteResult(
        resolvedParams,
        getResults(handler),
        routeExists: true,
        hasHandler: handler != null,
        actual: rootNode,
        tail: pathSegments.join('/'),
      );
    }
    
    if (!rootNode.terminal) {
      // Route path exists but is not a terminal node (no handlers registered)
      return RouteResult(
        resolvedParams,
        getResults(null),
        routeExists: false,
        hasHandler: false,
      );
    }
    final handler = rootNode.getHandler(method);
    return RouteResult(
      resolvedParams,
      getResults(handler),
      routeExists: true,
      hasHandler: handler != null,
      actual: rootNode,
    );
  }

  final _pathCache = <Object, List<String>>{};

  @pragma('vm:prefer-inline')
  /// Gets the route path segments for the given [route].
  List<String> getRoutePathSegments(Object route) {
    final cached = _pathCache[route];
    if (cached != null) {
      return cached;
    }

    late final List<String> segments;

    if (route is Uri) {
      segments = route.pathSegments;
    } else if (identical(route, basePath) || route == '/') {
      segments = const <String>[];
    } else if (identical(route, WildcardNode.key)) {
      segments = const [WildcardNode.key];
    } else if (identical(route, TailWildcardNode.key)) {
      segments = const [TailWildcardNode.key];
    } else {
      var path = route.toString();
      if (path.isEmpty) {
        segments = const <String>[];
      } else {
        final start = path.startsWith(basePath) ? 1 : 0;
        final end = path.endsWith(basePath) ? path.length - 1 : path.length;
        segments = path.substring(start, end).split('/');
      }
    }

    return _pathCache[route] = segments;
  }
}

/// The result of a route lookup, containing parameters and handler values.
final class RouteResult<T> {
  final List<ParamAndValue> _params;
  final List<Indexed<T>> _values;

  /// this is either a Node or Parametric Definition
  @visibleForTesting
  final Object? actual;

  /// Indicates whether the route path exists in the routing tree.
  /// This is true even if no handler exists for the requested method.
  final bool routeExists;

  /// Indicates whether a handler for the specified HTTP method was found.
  final bool hasHandler;

  /// The remaining path segments when a TailWildcardNode (**) is matched.
  /// This is null if the route was not matched by a tail wildcard.
  final String? tail;

  /// Creates an instance of [RouteResult].
  RouteResult(
    this._params,
    this._values, {
    this.routeExists = false,
    this.hasHandler = false,
    this.actual,
    this.tail,
  });

  Iterable<T>? _cachedValues;
  /// The handler values associated with the route.
  Iterable<T> get values {
    if (_cachedValues != null) {
      return _cachedValues!;
    }
    _values.sort((a, b) => a.index.compareTo(b.index));
    return _cachedValues = _values.map((e) => e.value);
  }

  Map<String, dynamic>? _cachedParams;
  /// The parameters extracted from the route.
  Map<String, dynamic> get params {
    if (_cachedParams != null) {
      return _cachedParams!;
    }
    return _cachedParams = {for (final entry in _params) entry.name: entry.value};
  }
}
