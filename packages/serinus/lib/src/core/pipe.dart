import 'dart:async';

import 'package:serinus/serinus.dart';

abstract class Pipe {

  Future<void> transform({
    required Request request,
  });

}