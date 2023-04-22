// coverage:ignore-file
import 'package:serinus/serinus.dart';

import '../data/data.module.dart';
import 'app.controller.dart';

@Module(
  imports: [DataModule()],
  controllers: [AppController],
)
class AppModule extends SerinusModule{}