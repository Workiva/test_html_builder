import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

void main() async {
  // Run a build with a filter for just the dart test config (which should be
  // quick). We need this file to be up-to-date so we can build the correct
  // command with build filters for each of the intended test paths.
  var executable = 'pub';
  var args = [
    'run',
    'build_runner',
    'build',
    '--build-filter=test/dart_test.dart2js_aggregate.yaml'
  ];
  stdout
    ..writeln('Building dart2js aggregate test config...')
    ..writeln('$executable ${args.join(' ')}');
  var process = await Process.start(executable, args,
      mode: ProcessStartMode.inheritStdio);
  exitCode = await process.exitCode;
  if (exitCode != 0) return;

  await Future<void>.delayed(Duration(seconds: 3));

  // Parse the generated test config to get the paths for each test that will be
  // run, so that we can generate the correct --build-filter args.
  stdout..writeln()..writeln('Reading dart2js aggregate test config...');
  final configFile = File('test/dart_test.dart2js_aggregate.yaml');
  final config =
      loadYaml(configFile.readAsStringSync(), sourceUrl: configFile.uri);
  List<String> paths;
  try {
    paths = List<String>.from(config['presets']['dart2js-aggregate']['paths']);
  } catch (e, stack) {
    stderr
      ..writeln('Failed to read test paths from "${configFile.uri}')
      ..writeln(e)
      ..writeln(stack);
    exitCode = 1;
    return;
  }
  stdout.writeln('Found ${paths.length} aggregate tests to run.');

  // TODO: verify that root dart_test.yaml includes test/dart_test.dart2js_aggregate.yaml

  // Build tests in release mode with the right build filters so that only the
  // aggregate tests and supporting files are built, and then run tests with the
  // right preset so that only those aggregate tests run. For projects with a
  // lot of tests, this will be much faster than compiling each individual test
  // with dart2js.
  args = [
    'run', 'build_runner', 'test', // '--release',
    for (final path in paths) '--build-filter=${p.setExtension(path, '.**')}',
    '--',
    '--preset',
    'dart2js-aggregate'
  ];
  stdout
    ..writeln()
    ..writeln('Running aggregate dart2js tests...')
    ..writeln('$executable ${args.join(' ')}');
  process = await Process.start(executable, args,
      mode: ProcessStartMode.inheritStdio);
  exitCode = await process.exitCode;
}
