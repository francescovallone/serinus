import 'package:serinus/serinus.dart';
import 'package:meta/meta.dart';
import 'package:serinus/src/utils/container_utils.dart';

abstract class SerinusModule{

  const SerinusModule();

  configure(MiddlewareConsumer consumer){}

  @nonVirtual
  Module get annotation => getModule(this);
}