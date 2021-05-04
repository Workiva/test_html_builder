import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

final argParser = ArgParser()
  ..addFlag('help', abbr: 'h')
  ..addFlag('debug',
      defaultsTo: false,
      help: 'Omits the --release flag to help with debugging.')
  ..addOption('mode',
      allowed: ['args', 'build', 'test'],
      allowedHelp: {
        'args':
            'Print to stderr the build and test args needed to run dart2js aggregate tests.\n'
                'Useful for integrating this into other test runners.',
        'build': 'Build the dart2js aggregate tests.',
        'test': 'Build and run dart2js aggregate tests.',
      },
      defaultsTo: 'test');

enum Mode {
  // Print build and test args separated by `--`
  args,
  // Build dart2js aggregate tests in release mode
  build,
  // Build and run dart2js aggregate tests in release mode
  test,
}

void main(List<String> args) async {
  final parsed = argParser.parse(args);

  if (parsed['help'] ?? false) {
    stdout.writeln(argParser.usage);
    return;
  }

  final debug = (parsed['debug'] as bool) ?? false;
  Mode mode;
  switch (parsed['mode']) {
    case 'args':
      mode = Mode.args;
      break;
    case 'build':
      mode = Mode.build;
      break;
    default:
      mode = Mode.test;
      break;
  }

  void logIf(bool condition, String msg) {
    if (!condition) return;
    stdout.writeln(msg);
  }

  // Run a build with a filter for just the dart test config (which should be
  // quick). We need this file to be up-to-date so we can build the correct
  // command with build filters for each of the intended test paths.
  var executable = 'pub';
  var brArgs = [
    'run',
    'build_runner',
    'build',
    '--build-filter=test/dart_test.dart2js_aggregate.yaml'
  ];
  logIf(mode != Mode.args, 'Building dart2js aggregate test config...');
  logIf(mode != Mode.args, '$executable ${brArgs.join(' ')}');
  var result = Process.runSync(executable, brArgs);
  logIf(result.exitCode != 0 || mode != Mode.args,
      '${result.stderr}\n${result.stdout}');
  if (result.exitCode != 0) {
    exitCode = result.exitCode;
    return;
  }

  // Parse the generated test config to get the paths for each test that will be
  // run, so that we can generate the correct --build-filter args.
  logIf(mode != Mode.args, '\nReading dart2js aggregate test config...');
  final configFile = File('test/dart_test.dart2js_aggregate.yaml');
  if (!configFile.existsSync()) {
    stdout
        .writeln(r'''dart2js aggregation is not enabled. Update your build.yaml:

# build.yaml
targets:
  $default:
    builders:
      test_html_builder:
        options:
          dart2js_aggregation: true''');
    exitCode = 1;
    return;
  }

  final config =
      loadYaml(configFile.readAsStringSync(), sourceUrl: configFile.uri);
  List<String> paths;
  try {
    paths = List<String>.from(config['presets']['dart2js-aggregate']['paths']);
  } catch (e, stack) {
    stdout
      ..writeln('Failed to read test paths from "${configFile.uri}')
      ..writeln(e)
      ..writeln(stack);
    exitCode = 1;
    return;
  }
  logIf(mode != Mode.args, 'Found ${paths.length} aggregate tests to run.');

  // Build tests in release mode with the right build filters so that only the
  // aggregate tests and supporting files are built, and then run tests with the
  // right preset so that only those aggregate tests run. For projects with a
  // lot of tests, this will be much faster than compiling each individual test
  // with dart2js.
  final buildArgs = [
    if (!debug) '--release',
    for (final path in paths) '--build-filter=${p.setExtension(path, '.**')}',
  ];
  final testArgs = [
    '--',
    '--preset=dart2js-aggregate',
  ];

  if (mode == Mode.args) {
    stdout.write([...buildArgs, ...testArgs].join(' '));
    return;
  }

  brArgs = [
    'run',
    'build_runner',
    if (mode == Mode.build) 'build',
    if (mode == Mode.test) 'test',
    ...buildArgs,
    if (mode == Mode.test) ...testArgs,
  ];
  stdout
    ..writeln()
    ..writeln(
        '${mode == Mode.build ? 'Building' : 'Running'} aggregate dart2js tests...')
    ..writeln('$executable ${brArgs.join(' ')}');
  final process = await Process.start(executable, brArgs,
      mode: ProcessStartMode.inheritStdio);
  exitCode = await process.exitCode;
}
