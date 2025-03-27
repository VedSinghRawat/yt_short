import 'dart:io';

void main() async {
  await _run('flutter', ['pub', 'get']);
  await _run('dart', ['run', 'build_runner', 'watch', '--d']);
}

Future<void> _run(String cmd, List<String> args) async {
  final process = await Process.start(cmd, args, runInShell: true);
  await stdout.addStream(process.stdout);
  await stderr.addStream(process.stderr);
}
