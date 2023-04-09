import 'package:serinus/src/decorators/route.dart';
import 'package:serinus/src/enums/method.dart';

class Get extends Route{
  const Get(super.path, {super.statusCode});
}

class Post extends Route {
  const Post(String path, {int? statusCode}) : super(path, method: Method.post, statusCode: statusCode ?? 201);
}

class Put extends Route{
  const Put(String path, {int? statusCode}) : super(path, method: Method.put, statusCode: statusCode ?? 200);
}

class Delete extends Route{
  const Delete(String path, {int? statusCode}) : super(path, method: Method.delete, statusCode: statusCode ?? 200);
}

class Patch extends Route{
  const Patch(String path, {int? statusCode}) : super(path, method: Method.patch, statusCode: statusCode ?? 200);
}

class Head extends Route{
  const Head(String path, {int? statusCode}) : super(path, method: Method.head, statusCode: statusCode ?? 200);
}

class Options extends Route{
  const Options(String path, {int? statusCode}) : super(path, method: Method.options, statusCode: statusCode ?? 200);
}
