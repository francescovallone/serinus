![Serinus Banner](https://raw.githubusercontent.com/francescovallone/serinus/main/packages/serinus/assets/github-header.png)

# Serve Static

Serve Static is a package that allows you to serve static files in your Serinus application.

## Installation

```bash
dart pub add serinus_serve_static
```

## Usage

```dart
class AppModule extends Module {
  AppModule()
      : super(
          imports: [ServeStaticModule()],
          controllers: [AppController()],
          providers: [AppProvider()],
        );
}
```
