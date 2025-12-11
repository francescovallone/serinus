# Changelog

## 2.1.0

**Released on:** Unreleased

### Features

- Add `ClassProvider` to allow inheritance in providers. Now it is possible to pass a class as a provider and have it injected as its subclass. This allows for better abstraction and separation of concerns in the application architecture.
- Add `etag` to requests to allow for better caching strategies and reduce bandwidth usage.
- Replace Spanner with Atlas as the default router for Serinus applications. Atlas provides better performance and more features compared to Spanner allowing for something more robust and flexible routing system.
- Allows to disable versioning on specific routes or controllers. This provides more flexibility in managing API versions and allows for better control over the versioning strategy.

### Fixes

- Fix WebSocket upgrade handling to prevent wrongful exceptions during connection upgrades.

## 2.0.3

- fix: add `ResponseContext#body` to early close the response on hooks, exceptions, and middlewares.

## 2.0.2

- fix(#203): when default maxRequests is used in RateLimiterHook the app doesn't start up properly. [#204](https://github.com/francescovallone/serinus/pulls/204) by [francescovallone](https://github.com/francescovallone)

## 2.0.1

- ci: add pana to serinus workflow
- fix: gentle close the web socket connections when application shuts down
- feat: add `bodyAsList<T>()` to parse lists of elements

## 2.0.0

- feat: add ComposedModule to allow for better composition of modules.
- fix: WebSocketGateway now correctly converts data before sending it.
- fix: correct handling of request body from previous erroneous implementation in 2.0.0-rc.5.
- fix: correct assignment of WsAdapter to the WebSocketGateway to prevent wrongful exceptions on sending data.
- ref!: remove ParseSchema completely from Serinus.
- feat: add onPart callback to the FormData parsing to allow for custom handling of each part of the multipart/form-data.
- feat: add simple hooks implementation to simplify the implementation of hooks in routes and controllers.
- feat: add shouldValidateMultipart to the RouteHandler to allow for manual validation of multipart/form-data requests.
- feat: improve body parsing to allow for more flexibility in the implementation of custom body types.
- feat: add utility methods to the RequestContext to simplify the extraction of typed parameters from the request.
- fix: fix check on WebSocketGateway to prevent wrongful exceptions on sending data.
- fix: reinstantiate module providers on deferred provider add to it
- fix: global prefix and versioning are now applied correctly to all routes
- feat!: change `Provider.deferred` to `Provider.composed` to better reflect its purpose.
- ref!: Controller path is now a required parameter.
- ref!: View Engine now has just a single method for rendering templates.
- ref!: View and ViewString are now one single class with two factory constructors.
- ref!: Middlewares are now registered using a fluent API.
- ref!: The `Module#registerAsync` method now must return a DynamicModule
- ref!: Each body type is now a separate class
- ref!: Request and Response Hooks are now divided.
- ref!: Some Hooks have now different method signatures.
- ref!: Renamed ResponseProperties to ResponseContext
- ref!: The Logger has been refactored to allow for more flexibility in the implementation.
- ref!: SerinusExceptions message is now a required parameter.
- ref!: Global definitions are now module-scoped.

## 1.0.6

- fix: add sigterm and sighup to correctly handle termination signals in the application. [#192](https://github.com/francescovallone/serinus/pulls/192) by [mdex-geek](https://github.com/mdex-geek)

## 1.0.5

- fix: reinstantiate module providers on deferred provider add to it

## 1.0.4

- fix(#172): fix the issue with the `UploadFile` method to correctly handle the file upload in the request body. [#173](https://github.com/francescovallone/serinus/pulls/173)

## 1.0.3

- chore: format the codebase with the latest version of dartfmt

## 1.0.2

- chore: update dependencies to the latest version

## 1.0.1

- chore: update dependencies to the latest version

## 1.0.0

This first stable release is packed with game-changing features designed to elevate your development experience:

- ModelProvider for seamless serialization and deserialization of JSON and form-data
- Typed Bodies to ensure type-safety when dealing with the request body.
- Client Generation for easy API integration
- Static Routes for optimized performance
- Lifecycle hooks to enhance control
- Improved dependency injection for cleaner architecture

## 1.0.0-rc.4

- feat(#104): add form data support to the models system.

## 1.0.0-rc.3

- feat: add a sealed class families to define a JsonBody object.
- feat: decouple the adapters allowing for more flexibility in the implementation of the adapters.

## 1.0.0-rc.2

- fix: change dependency constraints to ensure compatibility with the latest version of the packages

## 1.0.0-rc.1

- feat: first release candidate of Serinus 1.0.0

## 0.6.2

- chore: update spanner to 1.0.3

## 0.6.1

- fix: fix exported providers

## 0.6.0

- feat(#52): add streamable response to handle stream in responses. [#55](https://github.com/francescovallone/serinus/pull/55)
- feat(lab): change completely how Serinus handle responses. [#54](https://github.com/francescovallone/serinus/pull/54)

## 0.6.0-dev.5

- feat(#57): abstract ParseSchema to allow for more flexibility in the implementation of the schema parsers.

## 0.6.0-dev.4

- refactor(#39): add parent providers in child providers to allow for a better specialization of the behavior of the providers.
- refactor(#39): refactor contexts to unify common interfaces and methods.

## 0.6.0-dev.3

- fix(#39): fix canUse to use the correct type instead of dynamic.

## 0.6.0-dev.2

- feat(#39): add canUse and canStat methods to the request context to check if a provider or a metadata is present in the context.

## 0.6.0-dev.1

- feat(#39): add metadata system to Serinus to specialize the behavior of routes and controllers.

## 0.5.2

- fix: accept List of JsonObject as possible data in Response.json. [#42](https://github.com/francescovallone/serinus/issues/42)
- fix: Response.render & Response.renderString should close the request correctly. [#41](https://github.com/francescovallone/serinus/issues/41)
- fix: ParseSchema should insert back the parsed values in the request. [#45](https://github.com/francescovallone/serinus/issues/45)
- fix: The headers passed to the Response object are now set correctly.

## 0.5.1

- Add exports for Logger and ViewEngine

## 0.5.0

- feat(#36): add ParseSchema and remove parse hook to simplify validation in Serinus
- feat(#33): add interoperability with Shelf
- Add documentation for the Serinus CLI deploy command

## 0.4.1

- Fix another bug in the normalization route of the Controllers (#22)

## 0.4.0

- Add event-based response state (#14)
- Fix a bug in the normalization route of the Controllers when a leading slash is present (#22)
- Add request lifecycle hooks to the application both global and local (#18)
- Add Request Lifecycle documentation (#15)
- The Route class is now concrete and has several factory constructors to simplify the creation of routes (#16)
- The Response.file method now uses streams to send the file to the client (#17)

## 0.3.1

- Update Spanner to 1.0.1+5
- Add Body size limit to the application
- Improve performances of the application (up to 25%)

## 0.3.0

- Add WebSocket support
- Fix a bug in the ModulesContainer that caused a wrongful injection of the providers in the application.
- Abstract the Handler interface to allow for more flexibility in the implementation of the handlers

## 0.2.3

- Fix a bug in the ModulesContainer that caused a wrongful injection of the providers in the application.

## 0.2.2

- Add enableCompression flag in the SerinusApplication
- Clean up code and add more tests
- Start documenting the code

## 0.2.1

- Fix support for Serinus CLI run command environment variables
- Improve general performance
- Add Versioning to the Application
- Add GlobalPrefix to the Application
- Add ApplicationConfig to centralize the configuration of the application

## 0.2.0

- General performance improvements
- Refactor ViewEngines
- Add tests
- Add documentation
- Add support for Serinus CLI run command environment variables
- Simplify Route Handler signature (!!!BREAKING!!!)

## 0.1.1-dev.1

- Add support for Spanner as router
- Clean up code

## 0.1.0-dev.2

- Add DeferredModules
- Add scope to the ApplicationContext
- Fix Middlewares

## 0.1.0-dev.1

- Add DeferredProviders
- Fix parsing of path parameters in request

## 0.0.1-dev.5

- Add scoped providers to ExecutionContext

## 0.0.1-dev.4

- Huge refactoring of the code
- Add guards for the request
- Add pipes for the request

## 0.0.1-dev.3

- Added more exceptions
- Added ApplicationInit mixins
- Refactoring of the code and small fixes

## 0.0.1-dev.2

- Changed request route mapping
- Refactoring of the code and small fixes

## 0.0.1-dev.1

Initial Implementation
