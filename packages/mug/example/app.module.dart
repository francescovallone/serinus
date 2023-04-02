import 'package:mug/mug.dart';

import 'app.controller.dart';
import 'data/data.module.dart';

@Module(
  imports: [DataModule()],
  controllers: [AppController]
)
class AppModule extends MugModule{

  const AppModule();

}