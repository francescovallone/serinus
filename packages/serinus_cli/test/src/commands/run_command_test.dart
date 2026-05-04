import 'package:serinus_cli/src/commands/run/run_command.dart';
import 'package:test/test.dart';
import 'package:watcher/watcher.dart';

void main() {
  group('RunCommand.shouldRestartForEvent', () {
    final command = RunCommand();

    test('restarts for dart changes without a whitelist', () {
      final event = WatchEvent(ChangeType.MODIFY, 'lib/main.dart');

      final shouldRestart = command.shouldRestartForEvent(event, const []);

      expect(shouldRestart, isTrue);
    });

    test('restarts for non-dart files matched by whitelist', () {
      final event = WatchEvent(ChangeType.MODIFY, 'README.md');

      final shouldRestart = command.shouldRestartForEvent(
        event,
        const ['README.md'],
      );

      expect(shouldRestart, isTrue);
    });

    test('restarts for globbed whitelist matches', () {
      final event = WatchEvent(ChangeType.MODIFY, 'lib/generated/config.json');

      final shouldRestart = command.shouldRestartForEvent(
        event,
        const ['lib/**'],
      );

      expect(shouldRestart, isTrue);
    });

    test('does not restart for unrelated non-dart files', () {
      final event = WatchEvent(ChangeType.MODIFY, 'tool/cache.txt');

      final shouldRestart = command.shouldRestartForEvent(
        event,
        const ['README.md'],
      );

      expect(shouldRestart, isFalse);
    });
  });
}
