# Database

Serinus is database agnostic, allowing you to use any database of your choice. You can use any Dart database client or ORM that supports Dart, such as `postgres`, `drift`, etc.

For convenience Serinus provides tight integration with `loxia`, a powerful ORM for Dart. With `loxia`, you can define your database models and relationships using Dart classes. This integration provides additional Serinus-specific features, such as automatic model registration and seamless integration with Serinus's dependency injection system.

## Loxia Integration

To use `loxia` with Serinus, simply add the `serinus_loxia` and `loxia` packages to your project and define your database models as Dart classes. 

```bash
dart pub add serinus_loxia loxia
```

Then, you can define your models and use them in your Serinus application. For example:

```dart
import 'package:loxia/loxia.dart';ù

part 'user.g.dart';

@EntityMeta()
class User extends Entity {
  @PrimaryKey(autoIncrement: true)
  final int id;

  @Column()
  final String name;

  const User({required this.id, required this.name});

  static final entity = $UserEntityDescriptor;
}
```

Now we can add the `LoxiaModule` to our Serinus application to enable the integration:

```dart
import 'package:serinus/serinus.dart';
import 'package:serinus_loxia/serinus_loxia.dart';

class AppModule extends Module {
  AppModule()
    : super(
        imports: [
          LoxiaModule.inMemory(entities: [User.entity]),
        ],
        controllers: [UserController()],
      );
}
```

With this setup, you have now registered the `User` model with `loxia` but to use it you need to inject another module, the `LoxiaFeatureModule` that can easily be created with the `features` method of `LoxiaModule`:

```dart
import 'package:serinus/serinus.dart';

class AppModule extends Module {
  AppModule()
	: super(
		imports: [
		  LoxiaModule.inMemory(entities: [User.entity]),
		  LoxiaModule.features(entities: [User]),
		],
		controllers: [UserController()],
	  );
}
```

This will automatically register the necessary repositories for the `User` model, allowing you to easily perform database operations in your controllers and services.

```dart
import 'package:serinus/serinus.dart';

class UserController extends Controller {
  UserController() : super('/') {
    on(Route.get('/'), (context) async {
      final repo = context.use<UserRepository>();
      final users = await repo.paginate(
        page: context.query['page'] != null
            ? int.tryParse(context.query['page']!) ?? 1
            : 1,
        pageSize: context.query['pageSize'] != null
            ? int.tryParse(context.query['pageSize']!) ?? 10
            : 10,
      );
      final usersFull = await repo.findBy();
      return {
        'users': users.items,
        'total': users.total,
        'page': users.page,
        'pageSize': users.pageSize,
        'usersFull': usersFull.map((e) => e.toJson()).toList(),
      };
    });
    on(Route.post('/'), (RequestContext<Map<String, dynamic>> context) async {
      final repo = context.use<UserRepository>();
      final data = context.body;
      if (data['name'] == null) {
        throw BadRequestException('Missing name');
      }
      final column = await repo.insert(UserInsertDto(name: data['name']));
      return column;
    });
  }
}
```