# Changelog

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
