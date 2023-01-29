class Route{

  final String path;
  final String method;
  final int statusCode;

  const Route(this.path, {this.method = "GET", this.statusCode = 200});

}
