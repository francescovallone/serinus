import 'edge.dart';
import 'node.dart';

class SerializedGraph {

  final Map<String, Node> nodes = {};
  
  final Map<String, Edge> edges = {};

  Node insertNode(Node node) {
    if(nodes.containsKey(node.id)) {
      return nodes[node.id]!;
    }
    nodes[node.id] = node;
    return node;
  }

  Edge insertEdge(Edge edge) {
    if(edges.containsKey(edge.id)) {
      return edges[edge.id]!;
    }
    edges[edge.id] = edge;
    return edge;
  }



}