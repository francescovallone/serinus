import 'package:serinus/serinus.dart';

mixin OnApplicationInit on Provider {
  Future<void> onApplicationInit();
}

mixin OnApplicationShutdown on Provider {
  Future<void> onApplicationShutdown();
}