import 'dart:io';

Future<void> _run(String cmd, List<String> args) async {
  final process = await Process.start(cmd, args, runInShell: true);
  await stdout.addStream(process.stdout);
  await stderr.addStream(process.stderr);
}

void main() async {
  await _run('flutter', ['build', 'apk', '--release']);
  await _run('flutter', ['build', 'apk', '--debug']);
}
