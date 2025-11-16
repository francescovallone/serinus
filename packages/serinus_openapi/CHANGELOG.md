# Changelog

## 1.0.11

- fix(#206): OpenAPI UI not rendering when `analyze: false` in production. [#207](https://github.com/francescovallone/serinus/pull/207) by [developerjamiu](https://github.com/developerjamiu)

## 1.0.10

- fix: add exception responses in method handler analysis

## 1.0.9

- fix: fix issue when model in model provider is dynamic

## 1.0.8

- feat: add generation of OpenAPI type from simple object augmented with JsonObject without needing to adding it to the model provider.
- fix: issue with parsing models in modelProvider.
- fix: if analyze is false, it won't regenerate the specification file.

## 1.0.7

- feat: add `includePaths` param to specify which paths to include in the analysis. By default it includes 'lib' and 'bin' folders.
- fix: both methods and functions parameters can now be analyzed for request bodies.

## 1.0.6

- chore: remove print

## 1.0.5

- fix: add analysis of request bodies when handler is a method of the controller

## 1.0.4

- feat: add `optimizedAnalysis` params to make the analyzer ignore files with lastModification older than the specification file.
- fix: remove wrongful condition in the first if.

## 1.0.3

- fix: Correctly document built-in and custom exceptions in OpenAPI spec.

## 1.0.2

- fix(#205): Ensure SwaggerUI Render works correctly out of the box.

## 1.0.1

- Fix usage example in README.md.

## 1.0.0

- Initial version.
