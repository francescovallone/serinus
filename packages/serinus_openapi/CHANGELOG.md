# Changelog

## 1.1.0

- feat: add a complete test suite for `serinus_openapi` (annotations, analyzer, routes, schema descriptors, renderers, and module factories).
- feat: document a custom annotation example in README (`OperationId` pattern based on `OpenApiAnnotation`).
- fix: avoid invalid OpenAPI v3 initialization by ensuring `DocumentV3.paths` is never empty in `OpenApiModule.v3`.
- fix: make OpenAPI document generation resilient when analyzed v3 paths are empty by reusing existing document paths or a safe default path.
- fix: prevent Dart SDK core types (for example `List`) from being registered as generated model schemas during analyzer model registration.
- fix: align v3/v3.1 response handling in `OpenApiRegistry` with non-null `responses` API from `openapi_types`.
- chore: bump package version to `1.1.0`.
- chore: update `openapi_types` dependency to `^2.1.0`.
- docs/example: update package example to use `ScalarUIOptions` and refresh generated `openapi.yaml` output.


## 1.0.14

- chore: update dependencies.

## 1.0.13

- fix: ensure OpenAPI spec is generated when analyze is false but the spec file does not exist.

## 1.0.12

- feat: add operationId to analyzed method handler and use it in OpenAPI generation.

## 1.0.11

- fix(#206): OpenAPI UI not rendering when `analyze: false` in production. [#207](https://github.com/francescovallone/serinus/pull/207) by [developerjamiu](https://github.com/developerjamiu)

## 1.0.10

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
