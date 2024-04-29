extension CombineUriPath on Uri {
  List<String> combinePath() {
    List<String> pathSegments = this.pathSegments;

    if (pathSegments.isEmpty) {
      return [];
    }

    List<String> combinedPath = [];

    for (int i = 0; i < pathSegments.length; i++) {
      if (i == 0) {
        combinedPath.add(pathSegments[i]);
      } else {
        combinedPath.add('${combinedPath[i - 1]}/${pathSegments[i]}');
      }
    }

    return combinedPath;
  }
}
