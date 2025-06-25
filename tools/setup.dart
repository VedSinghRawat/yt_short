import 'dart:io';

void main() async {
  await runCommand('flutter', ['clean']);

  // Delete all .g.dart and .freezed.dart files
  final dir = Directory('lib');
  await for (final entity in dir.list(recursive: true)) {
    if (entity is File && (entity.path.endsWith('.g.dart') || entity.path.endsWith('.freezed.dart'))) {
      await entity.delete();
    }
  }

  await runCommand('flutter', ['pub', 'get']);
  await runCommand('dart', ['run', 'build_runner', 'watch', '--delete-conflicting-outputs']);
}

Future<void> runCommand(String cmd, List<String> args) async {
  final process = await Process.start(cmd, args, runInShell: true);
  await stdout.addStream(process.stdout);
  await stderr.addStream(process.stderr);
}
