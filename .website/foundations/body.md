# Body

As you already saw in the [Controller](/controllers) page, you can define a static typed body for your routes but what if you want the raw body of the request?
Well you can do that too, Serinus provides a way to access the raw body of the request using the `body` property of the `RequestContext` object.

The Serinus Body, however, is a bit different from the standard `HttpRequest` body. It is a `Body` object that provides some useful methods to work with the body of the request.

First of all it contains the 4 main types of body that can be sent in a request:

- `formData`: A body that contains form data.
- `text`: The content of the body if it is text.
- `bytes`: The content of the body if it is binary.
- `json`: The content of the body if it is json.

If you are unsure which is the type of the body, you can just access it using the `value` property.

```dart
import 'package:serinus/serinus.dart';

class UserController extends Controller {
  UserController(): super(path: '/users') {
	on(Route.post('/'), createUser);
  }

  Future<User?> createUser(RequestContext context) async {
	final body = context.body.value;
	if(body is JsonBody && !body.multiple) {
	  return User.fromJson(body.value);
	}
	return null;
  }
}
```

In the example above, we check if the body is a `JsonBody` and if it is not a list of elements but just one. If it is, we parse the body to a `User` object.

The `JsonBody` is actually a utility class that describes a `JsonBodyObject` and a `JsonList`.

The `JsonBodyObject` is a body that contains a single json object and the `JsonList` is a body that contains a list of json objects. They both follow the same interface as the JsonBody.
