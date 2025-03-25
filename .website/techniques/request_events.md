# Request Events

If you don't want to use the full power of the `Hooks` object, Serinus provides a way to listen to specific events of a request. Although not so specific as the `Hooks` object, the `RequestEvent`s are a good way to listen to the most common events of a request and act accordingly.

To listen to request events, you just need to call the method `on` of the `Request` object. The method takes two arguments: the event name and a callback function. The most common case where the `RequestEvent`s are useful is in Middlewares to log, or handle errors, or even to close resources when the request is closed.

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
