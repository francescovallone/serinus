import 'dart:io';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:mason/mason.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pub_updater/pub_updater.dart';
import 'package:serinus_cli/src/command_runner.dart';
import 'package:serinus_cli/src/commands/commands.dart';
import 'package:serinus_cli/src/version.dart' as version;
import 'package:test/test.dart';

class _MockLogger extends Mock implements Logger {}

class _MockProgress extends Mock implements Progress {}

class _FakeTargetDirectory extends Fake implements DirectoryGeneratorTarget {}

class _MockArgResults extends Mock implements ArgResults {}

void main() {
  const latestVersion = '0.0.0';

  group('create', () {
    late ArgResults argResults;
    late Logger logger;
    late Progress progress;
    late CreateCommand command;

    setUpAll(() {
      registerFallbackValue(_FakeTargetDirectory());
    });

    setUp(() {
      final progress = _MockProgress();
      logger = _MockLogger();
      when(() => logger.progress(any())).thenReturn(progress);
      argResults = _MockArgResults();
      command = CreateCommand(
        logger: logger,
      )
        ..testArgResults = argResults
        ..testUsage = 'test usage';
    });

    test('throws UsageException when no project-name is provided', () async {
      when(() => argResults.rest).thenReturn([]);
      when<dynamic>(() => argResults['project-name']).thenReturn(null);
      expect(command.run, throwsA(isA<UsageException>()));
    });

    test('throws UsageException when more than 1 args are provided', () async {
      when(() => argResults.rest).thenReturn(['test', 'many', 'args', 'hello']);
      when<dynamic>(() => argResults['project-name']).thenReturn(null);
      expect(command.run, throwsA(isA<UsageException>()));
    });

    test('throws UsageException when no project-name is provided', () async {
      final directory = Directory.systemTemp.createTempSync();
      when(() => argResults.rest).thenReturn([directory.path]);
      when<dynamic>(
        () => argResults['project-name'],
      ).thenReturn('invalid name');
      expect(command.run, throwsA(isA<UsageException>()));
    });

    test('throws UsageException when project directory is invalid.', () async {
      final directory = Directory.systemTemp.createTempSync();
      when(() => argResults.rest).thenReturn([directory.path, directory.path]);
      when<dynamic>(() => argResults['project-name']).thenReturn(null);
      expect(command.run, throwsA(isA<UsageException>()));
    });

  });
}
