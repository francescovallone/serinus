# Changelog

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
