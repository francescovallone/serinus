# Globe

Globe is a service developed by [Invertase](https://invertase.io) that provides a simple way to deploy you Flutter and Dart applications to the web.

## Getting Started

To get started with Globe, we will need to install the Globe CLI. We can do this by running the following command:

```bash
dart pub global activate globe
```

Once we have installed the Globe CLI, we will need to login to your Globe account. We can do this by running the following command:

```bash
globe login
```

## Deploying Your Application

Before deploying our application we need to change some lines in our entrypoint file. We need to change the following lines:

```dart{6}
import 'package:serinus/serinus.dart';

Future<void> bootstrap() async {
  final app = await serinus.createApplication(
      entrypoint: AppModule(), 
      host: '0.0.0.0', 
      port: 3000 // [!code --]
      port: 8080 // [!code ++]
    ); 
      
  await app.serve();
}
```

Now we can deploy our application by running the following command:

```bash
globe deploy
```

When prompted to enter the path to your entrypoint file, enter the path to your entrypoint file in your project. If you use the serinus cli to create your project, the entrypoint file will be located in the `bin` directory.

This will deploy your application to the Globe service and provide you with a URL to access your application.
