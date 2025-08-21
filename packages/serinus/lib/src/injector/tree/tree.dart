class TreeNode<T> {
  T value;
  TreeNode<T>? parent;
  final Set<TreeNode<T>> children = {};

  TreeNode(this.value, {this.parent});

  void addChild(TreeNode<T> child) {
    child.parent = this;
    children.add(child);
  }

  void relink(TreeNode<T> parent) {
    parent.children.remove(this);
    parent = parent;
    parent.addChild(this);
  }

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