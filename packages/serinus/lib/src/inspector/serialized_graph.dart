import '../containers/injection_token.dart';
import 'edge.dart';
import 'entrypoint.dart';
import 'node.dart';

/// The [SerializedGraph] class is used as a base class for the graph inspector.
/// It contains the nodes and edges of the graph.
class SerializedGraph {
  /// The Map of nodes in the graph.
  final Map<InjectionToken, Node> nodes = {};

  /// The Map of edges in the graph.
  final Map<String, Edge> edges = {};

  final Map<String, Entrypoint> entrypoints = {};

  /// Inserts a node into the graph.
  Node insertNode(Node node) {
    if (nodes.containsKey(node.id)) {
      return nodes[node.id]!;
    }
    nodes[node.id] = node;
    return node;
  }

  /// Inserts an edge into the graph.
  Edge insertEdge(Edge edge) {
    if (edges.containsKey(edge.id)) {
      return edges[edge.id]!;
    }
    edges[edge.id] = edge;
    return edge;
  }

  Entrypoint insertEntrypoint(Entrypoint entrypoint) {
    if (entrypoints.containsKey(entrypoint.id)) {
      return entrypoints[entrypoint.id]!;
    }
    entrypoints[entrypoint.id] = entrypoint;
    return entrypoint;
  }

  /// Converts the [SerializedGraph] to a JSON object.
  /// This is used to display the graph in the inspector.
  Map<String, dynamic> toJson() {
    return {
      'nodes': nodes.values.map((e) => e.toJson()).toList(),
      'edges': edges.values.map((e) => e.toJson()).toList(),
      'entrypoints': entrypoints.values.map((e) => e.toJson()).toList()
    };
  }
}
