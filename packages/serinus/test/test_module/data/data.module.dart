// coverage:ignore-file
import 'package:serinus/serinus.dart';

import 'data.controller.dart';
import 'data.service.dart';

@Module(
  imports: const [],
  controllers: const [DataController],
  providers: const [DataService]
)
class DataModule extends SerinusModule{

  const DataModule();
}