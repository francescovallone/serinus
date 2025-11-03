/// Represents a node in the tree.
class TreeNode<T> {
  /// The value stored in the node.
  T value;

  /// The parent of the node.
  TreeNode<T>? parent;

  /// The children of the node.
  final Set<TreeNode<T>> children = {};

  /// Creates a new instance of [TreeNode].
  TreeNode(this.value, {this.parent});

  /// Adds a child to the node.
  void addChild(TreeNode<T> child) {
    child.parent = this;
    children.add(child);
  }

  /// Relinks the node to a new parent.
  void relink(TreeNode<T> parent) {
    parent.children.remove(this);
    parent = parent;
    parent.addChild(this);
  }

  /// Gets the depth of the node in the tree.
  int get depth {
    int d = 0;
    TreeNode<T>? current = parent;
    final visited = <TreeNode<T>>{};
    while (current != null) {
      d++;
      current = current.parent;
      if (visited.contains(current)) {
        return -1; // Cycle detected
      }
      visited.add(current!);
    }
    return d;
  }

  /// Checks if the node has a cycle.
  bool hasCycle(T target) {
    final visited = <TreeNode<T>>{};
    TreeNode<T>? current = this;
    while (current != null) {
      if (current.value == target) {
        return true;
      }
      if (visited.contains(current)) {
        return true;
      }
      visited.add(current);
      current = current.parent;
    }
    return false;
  }
}
