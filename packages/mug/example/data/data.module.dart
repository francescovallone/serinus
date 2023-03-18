import '../../lib/mug.dart';

import 'data.controller.dart';
import 'data.service.dart';

@Module(
  imports: const [],
  controllers: const [DataController],
  providers: const [DataService]
)
class DataModule extends MugModule{

  const DataModule();
}