enum Method{
  get,
  post,
  delete,
  put,
  options,
  head,
  patch;

  @override
  String toString() {
    return this.name.toUpperCase();
  }
}

extension StringMethod on String {
  Method toMethod(){
    switch(this.toLowerCase()){
      case 'post':
        return Method.post;
      case 'put':
        return Method.put;
      case 'delete':
        return Method.delete;
      case 'options':
        return Method.options;
      case 'head':
        return Method.head;
      case 'patch':
        return Method.patch;
      default:
        return Method.get;
    }
  }
}