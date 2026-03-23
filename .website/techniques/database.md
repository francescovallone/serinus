---
outline: [2, 4]
---
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
import 'package:loxia/loxia.dart';

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

### Multiple Databases

Serinus also supports using multiple databases in the same application. You can create multiple `LoxiaModule` instances with different configurations and import them into your main module. Each `LoxiaModule` will manage its own set of entities and repositories, allowing you to easily work with multiple databases in a single application.

```dart
import 'package:serinus/serinus.dart';

class AppModule extends Module {
  AppModule()
    : super(
        imports: [
          LoxiaModule.inMemory(entities: [User.entity]),
          LoxiaModule.features(entities: [User]),
          LoxiaModule.inMemory(entities: [Product.entity], name: 'products'),
          LoxiaModule.features(entities: [Product], name: 'products'),
        ],
        controllers: [UserController(), ProductController()],
      );
}

class ProductController extends Controller {
  ProductController() : super('/products') {
    on(Route.get('/'), (context) async {
      final repo = context.use<ProductRepository>('products');
      final products = await repo.paginate(
        page: context.query['page'] != null
            ? int.tryParse(context.query['page']!) ?? 1
            : 1,
        pageSize: context.query['pageSize'] != null
            ? int.tryParse(context.query['pageSize']!) ?? 10
            : 10,
      );
      return {
        'products': products.items,
        'total': products.total,
        'page': products.page,
        'pageSize': products.pageSize,
      };
    });
    on(Route.post('/'), (RequestContext<Map<String, dynamic>> context) async {
      final repo = context.use<ProductRepository>('products');
      final data = context.body;
      if (data['name'] == null) {
        throw BadRequestException('Missing name');
      }
      final column = await repo.insert(ProductInsertDto(name: data['name']));
      return column;
    });
  }
}
```

In this example, we have two `LoxiaModule` instances, one for managing `User` entities and another for managing `Product` entities. Each module is configured with its own set of entities and repositories, allowing you to easily work with both databases in your application.

To access the repositories from the different modules, you can specify the `name` when using the `context.use` method, as shown in the `ProductController` example above. This allows you to easily switch between different databases and manage your data effectively.

## Drift Integration

Serinus also provides integration with `drift`, the most popular ORM for Dart. With `drift`, you can define your database schema using Dart classes and perform database operations using a fluent API.

To use `drift` with Serinus, simply add the `serinus_drift`, `drift` and the `drift_dev` and `build_runner` packages to your project:

```bash
dart pub add drift serinus_drift dev:drift_dev dev:build_runner
```

Then, you can define your schema and use it in your Serinus application. For example:

```dart
import 'package:drift/drift.dart';
part 'user.g.dart';

class Users extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
}
```

Now we can create a `DriftDatabase` and a `DriftAccessor` to manage our database operations:

```dart
import 'package:drift/drift.dart';
import 'package:serinus/serinus.dart';
import 'package:serinus_drift/serinus_drift.dart';
import 'user.dart';
part 'app_database.g.dart';

@DriftDatabase(tables: [Users])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 1;
}

@DriftAccessor(tables: [Users])
class UsersDao extends DatabaseAccessor<AppDatabase> with _$UsersDaoMixin {
  UsersDao(super.db);

  Future<List<User>> getAllUsers() => select(users).get();
  Future<int> insertUser(UsersCompanion user) => into(users).insert(user);
}
```

Finally, we can add the `DriftModule` to our Serinus application to enable the integration:

```dart
import 'package:serinus/serinus.dart';
import 'package:serinus_drift/serinus_drift.dart';
import 'package:drift/native.dart';
import 'app_database.dart';

class AppModule extends Module {
  AppModule() : super(
    imports: [
      DriftModule(AppDatabase(NativeDatabase.memory())),
      DriftModule.forFeature<AppDatabase>(
        daos: (database) => [
          UsersDao(database)
        ], 
      ),
    ],
    controllers: [
      UserController()
    ]
  );
}
```

With this setup, you have now registered the `Users` table with `drift` and created a `UsersDao` to manage database operations. You can then inject the `UsersDao` into your controllers and services to perform database operations seamlessly within your Serinus application.

```dart
import 'package:serinus/serinus.dart';
import 'app_database.dart';

class UserController extends Controller {
  UserController() : super('/') {
    on(Route.get('/'), (context) async {
      final dao = context.use<UsersDao>();
      final users = await dao.getAllUsers();
      return users.map((e) => {'id': e.id, 'name': e.name}).toList();
    });
    on(Route.post('/'), (RequestContext<Map<String, dynamic>> context) async {
      final dao = context.use<UsersDao>();
      final data = context.body;
      if (data['name'] == null) {
        throw BadRequestException('Missing name');
      }
      final id = await dao.insertUser(UsersCompanion(name: Value(data['name'])));
      return {'id': id};
    });
  }
}
```
