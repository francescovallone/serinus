# Changelog

## 1.0.8 

- fix(#187): debounce the events executing only the last one.

## 1.0.7

- fix(cli_warning_port): remove default value from port when using cli, remove warnings regarding missing config.

## 1.0.6

- fix(#180): Prevent the cli from overwriting already existing files when running the `generate` command.

## 1.0.5

- fix(#177): Fix the Dockerfile generation to create the dist folder in the correct location.

## 1.0.4

- Remove useless print

## 1.0.3

- Add `--force` option to the `create` command to force the generation of the files even if they already exist.

## 1.0.2

- Update dependencies to the latest version.
- Update required Dart version to >= 3.5.0.
- Fix the `run` command and improved the how the cli reads the configuration.

## 1.0.1

- Update dependencies to the latest version.
- Fix `generate` command for the resources.

## 1.0.0

- Update the CLI to use the new version of the Serinus framework.
- Add generate models command to the CLI.
- Update generate command to be easier to use.
- Add generate client command to the CLI.
- Add deprecation warning for the old configuration file.

## 0.4.0

- Add generate command to the CLI.

## 0.3.0

- Add deploy command to the CLI. (#10)

## 0.2.3

- Re-add the dynamic fetch of the serinus version in the create command.

## 0.2.2

- Fix the create command.

## 0.2.1

- Fix the create command to use the pre and post gen hooks.

## 0.2.0

- Add build command to the CLI.

## 0.1.0-dev.1

- First release of the cli after the refactor of the whole framework.
- Usage of Bricks from the serinus-bricks package.

## 0.0.1

First release still in development and not ready for production use.
