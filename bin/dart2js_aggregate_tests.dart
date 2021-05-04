import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

const testPreset = '--preset=dart2js-aggregate';

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

void logIf(bool condition, String msg) {
  if (!condition) return;
  stdout.writeln(msg);
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

  buildDart2jsAggregateTestYaml(mode);
  final testPaths = parseAggregateTestPaths(mode);
  if (mode == Mode.args) {
    printArgs(testPaths, debug: debug);
  } else {
    await buildOrRunTests(mode, testPaths, debug: debug);
  }
}

/// Run a build with a filter for just the dart test config (which should be
/// quick).
///
/// We need this file to be up-to-date so we can build the correct command with
/// build filters for each of the intended test paths.
void buildDart2jsAggregateTestYaml(Mode mode) {
  var executable = 'pub';
  var args = [
    'run',
    'build_runner',
    'build',
    '--build-filter=test/dart_test.dart2js_aggregate.yaml'
  ];
  logIf(mode != Mode.args, 'Building dart2js aggregate test config...');
  logIf(mode != Mode.args, '$executable ${args.join(' ')}');
  var result = Process.runSync(executable, args);
  logIf(result.exitCode != 0 || mode != Mode.args,
      '${result.stderr}\n${result.stdout}');
  if (result.exitCode != 0) {
    exit(result.exitCode);
  }
}

/// Parse the generated test config to get the paths for each test that will be
/// run, so that we can generate the correct --build-filter args.
///
/// Returns the list of paths for all aggregate tests, or exits early if they
/// could not be parsed.
List<String> parseAggregateTestPaths(Mode mode) {
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
    exit(1);
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
    exit(1);
  }
  logIf(mode != Mode.args, 'Found ${paths.length} aggregate tests to run.');
  return paths;
}

/// Returns a list of args to be passed to a build_runner command that will only
/// build/run [tests].
///
/// The --release flag will be included unless [debug] is true.
List<String> buildRunnerBuildArgs(List<String> testPaths, {bool debug}) => [
      if (debug != true) '--release',
      for (final path in testPaths)
        '--build-filter=${p.setExtension(path, '.**')}',
    ];

/// Depending on [mode], either builds or builds and runs the aggregate tests
/// using [buildArgs] and [testArgs].
Future<void> buildOrRunTests(Mode mode, List<String> testPaths,
    {bool debug}) async {
  final executable = 'pub';
  final args = [
    'run',
    'build_runner',
    if (mode == Mode.build) 'build',
    if (mode == Mode.test) 'test',
    ...buildRunnerBuildArgs(testPaths, debug: debug),
    if (mode == Mode.test) ...['--', testPreset],
  ];
  stdout
    ..writeln()
    ..writeln(
        '${mode == Mode.build ? 'Building' : 'Running'} aggregate dart2js tests...')
    ..writeln('$executable ${args.join(' ')}');
  final process = await Process.start(executable, args,
      mode: ProcessStartMode.inheritStdio);
  exitCode = await process.exitCode;
}

/// Prints the build and test args separated by `--` needed to build or run the
/// dart2js aggregate tests.
void printArgs(List<String> testPaths, {bool debug}) {
  stdout.write([
    ...buildRunnerBuildArgs(testPaths, debug: debug),
    '--',
    testPreset,
  ].join(' '));
}
