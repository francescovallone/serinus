import 'package:serinus/src/core/contexts/application_context.dart';

abstract class Provider {

  final bool isGlobal;

  const Provider({this.isGlobal = false});

}

class DeferredProvider extends Provider {

  final Future<Provider> Function(ApplicationContext context) init;

  const DeferredProvider(
    this.init,
    {bool isGlobal = false}
  ) : super(isGlobal: isGlobal);

}