import 'dart:async';

import 'package:serinus/serinus.dart';

abstract class Pipe {

  FutureOr<void> transform({
    required Request request,
  });

}