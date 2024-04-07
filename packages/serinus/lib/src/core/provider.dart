import 'package:serinus/src/core/contexts/application_context.dart';

abstract class Provider {

  final bool isGlobal;

  const Provider({this.isGlobal = false});

}

class LazyProvider extends Provider {

  final Future<Provider> Function(ApplicationContext context) init;

  const LazyProvider(
    this.init,
    {bool isGlobal = false}
  ) : super(isGlobal: isGlobal);

}