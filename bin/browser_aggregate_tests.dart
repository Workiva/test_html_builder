import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

const testPreset = '--preset=browser-aggregate';

final argParser = ArgParser()
  ..addFlag('help', abbr: 'h')
  ..addFlag('release',
      defaultsTo: false, help: 'Build in release mode (dart2js).')
  ..addOption('mode',
      allowed: ['args', 'build', 'test'],
      allowedHelp: {
        'args':
            'Print to stderr the build and test args needed to run browser aggregate tests.\n'
                'Useful for integrating this into other test runners.',
        'build': 'Build the browser aggregate tests.',
        'test': 'Build and run browser aggregate tests.',
      },
      defaultsTo: 'test')
  ..addOption('build-args',
      help: 'Args to pass to the build runner process.\n'
          'Run "dart run build_runner build -h -v" to see all available '
          'options.');

enum Mode {
  // Print build and test args separated by `--`
  args,
  // Build browser aggregate tests
  build,
  // Build and run browser aggregate tests
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

  final bool? release = parsed['release'];
  final String? buildArgs = parsed['build-args'];

  buildAggregateTestYaml(mode, userBuildArgs: buildArgs);
  final testPaths = parseAggregateTestPaths(mode);
  if (mode == Mode.args) {
    printArgs(testPaths);
  } else if (mode == Mode.build) {
    await buildTests(testPaths, release: release, userBuildArgs: buildArgs);
  } else {
    await runTests(testPaths, release: release, userBuildArgs: buildArgs);
  }
}

/// Run a build with a filter for just the dart test config (which should be
/// quick).
///
/// We need this file to be up-to-date so we can build the correct command with
/// build filters for each of the intended test paths.
///
/// [userBuildArgs] is interpreted as a space delimited string of additional
/// build_runner build arguments and will also be included.
void buildAggregateTestYaml(Mode mode, {String? userBuildArgs}) {
  var executable = 'dart';
  var args = [
    'run',
    'build_runner',
    'build',
    // Because the builder triggered by this build writes files to source,
    // and we expect those files to be checked in, we will always need to
    // include --delete-conflicting-outputs.
    '--delete-conflicting-outputs',
    // Users may also supply additional build arguments. For example, some
    // repos may need to specify a custom build.yaml file to be used.
    ...?userBuildArgs?.split(' '),
    '--build-filter=dart_test.browser_aggregate.yaml'
  ];
  logIf(mode != Mode.args, 'Building browser aggregate test config...');
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
  logIf(mode != Mode.args, '\nReading browser aggregate test config...');
  final configFile = File('dart_test.browser_aggregate.yaml');
  if (!configFile.existsSync()) {
    stdout
        .writeln(r'''browser aggregation is not enabled. Update your build.yaml:

# build.yaml
targets:
  $default:
    builders:
      test_html_builder:
        options:
          browser_aggregation: true''');
    exit(1);
  }

  final config =
      loadYaml(configFile.readAsStringSync(), sourceUrl: configFile.uri);
  late List<String> paths;
  try {
    paths = List<String>.from(config['presets']['browser-aggregate']['paths']);
  } catch (e, stack) {
    stdout
      ..writeln('Failed to read test paths from "${configFile.uri}"')
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
/// The --release flag will be included if [release] is true.
///
/// [userBuildArgs] is interpreted as a space delimited string of additional
/// build_runner build arguments and will also be included.
List<String> buildRunnerBuildArgs(List<String> testPaths,
        {bool? release, String? userBuildArgs}) =>
    [
      ...?userBuildArgs?.split(' '),
      if (release ?? false) '--release',
      for (final path in testPaths)
        '--build-filter=${p.setExtension(path, '.**')}',
    ];

/// Builds aggregate tests at [testPaths].
///
/// Includes `--release` if [release] is true.
Future<void> buildTests(List<String> testPaths,
    {bool? release, String? userBuildArgs}) async {
  final executable = 'dart';
  final args = [
    'run',
    'build_runner',
    'build',
    ...buildRunnerBuildArgs(testPaths,
        release: release, userBuildArgs: userBuildArgs),
  ];
  stdout
    ..writeln()
    ..writeln('Building browser aggregate tests...')
    ..writeln('$executable ${args.join(' ')}');
  final process = await Process.start(executable, args,
      mode: ProcessStartMode.inheritStdio);
  exitCode = await process.exitCode;
}

/// Builds and runs aggregate tests at [testPaths].
///
/// Includes `--release` if [release] is true.
Future<void> runTests(List<String> testPaths,
    {bool? release, String? userBuildArgs}) async {
  final executable = 'dart';
  final args = [
    'run',
    'build_runner',
    'test',
    ...buildRunnerBuildArgs(testPaths,
        release: release, userBuildArgs: userBuildArgs),
    '--',
    testPreset,
  ];
  stdout
    ..writeln()
    ..writeln('Running browser aggregate tests...')
    ..writeln('$executable ${args.join(' ')}');
  final process = await Process.start(executable, args,
      mode: ProcessStartMode.inheritStdio);
  exitCode = await process.exitCode;
}

/// Prints the build and test args separated by `--` needed to build or run the
/// browser aggregate tests.
void printArgs(List<String> testPaths) {
  stdout.write([
    ...buildRunnerBuildArgs(testPaths),
    '--',
    testPreset,
  ].join(' '));
}
