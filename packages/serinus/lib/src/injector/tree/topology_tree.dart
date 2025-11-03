import '../../core/core.dart';
import 'tree.dart';

/// Represents the topology tree of modules.
class TopologyTree {
  TreeNode<Module>? _root;
  final Map<Module, TreeNode<Module>> _nodes = {};

  /// Creates a new instance of [TopologyTree].
  TopologyTree(Module module) {
    _root = TreeNode(module, parent: null);
    _nodes[module] = _root!;
    _buildNodes(_root!);
  }

  /// Walks the tree and applies the callback to each module.
  void walk(void Function(Module, int) callback) {
    void walkNode(TreeNode<Module> node, [int depth = 1]) {
      callback(node.value, depth);
      for (var child in node.children) {
        walkNode(child, depth + 1);
      }
    }

    walkNode(_root!);
  }

  void _buildNodes(TreeNode<Module> root, [int depth = 1]) {
    if (root.value.imports.isEmpty) {
      return;
    }
    for (final import in root.value.imports) {
      if (_nodes.containsKey(import)) {
        final existingNode = _nodes[import]!;
        if (existingNode.hasCycle(root.value)) {
          return;
        }
        final existingNodeDepth = existingNode.depth;
        if (existingNodeDepth < depth) {
          existingNode.relink(root);
        }
        return;
      }
      final newNode = TreeNode<Module>(import, parent: root);
      _nodes[import] = newNode;
      root.addChild(newNode);
      _buildNodes(newNode, depth + 1);
    }
  }
}
