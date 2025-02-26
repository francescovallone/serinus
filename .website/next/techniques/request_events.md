# Request Events

Request events are a way to hook into the request lifecycle and perform actions at specific points in the request. This can be useful for logging, debugging, or modifying the request before it is processed.

## Listening Request Events

You can listen to request events by calling the method `on` of the `Request` object. The method takes two arguments: the event name and a callback function.

```dart
import 'package:serinus/serinus.dart';

class RequestEventMiddleware extends Middleware {
  
  RequestEventMiddleware();

  @override
  Future<void> use(RequestContext context, NextFunction next) async {
    context.request.on(RequestEvent.close, (event, data) async {
      print("Request closed");
    });
    return next();
  }
}
```

The example above listens only to the `RequestEvent.close` event. The callback function will be called when the request is closed.

The following events are available:

| Event Name | Description |
|------------|-------------|
| RequestEvent.error | An error occurred during the request. |
| RequestEvent.redirect | The request is redirected. |
| RequestEvent.data | Data is received and sent to the response. |
| RequestEvent.close | The request is closed. |
| RequestEvent.all | All events. |

The callback function receives two arguments: the event name and the data associated with the event.
The data is of type `EventData` and contains the following properties:

- `exception`: The exception that occurred. (Only available for the `RequestEvent.error` event)
- `data`: The data received. (Available for all events except `RequestEvent.redirect`)
- `properties`: The properties of the response. (Available for all events)
- `hasException`: A boolean value that indicates if the event contains an error. (Available for all events)
