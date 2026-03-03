import 'package:serinus/serinus.dart';

import 'events_gateway.dart';

class EventsModule extends Module {
  EventsModule() : super(
    imports: [],
    controllers: [],
    providers: [
      EventsGateway(),
    ],
  );
}
