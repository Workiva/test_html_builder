@TestOn('vm')
@Timeout(Duration(minutes: 1))
import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:test_descriptor/test_descriptor.dart' as d;
import 'package:test_process/test_process.dart';

void main() {
  Future<String> createProject(
      {bool? browserAggregation, bool? customBuildYaml}) async {
    browserAggregation ??= true;
    customBuildYaml ??= false;
    await d.dir('pkg', [
      d.file('pubspec.yaml', '''name: pkg
environment:
  sdk: '>=2.12.0 <3.0.0'
dev_dependencies:
  build_runner: any
  build_test: any
  build_web_compilers: any
  test: any
  test_html_builder:
    path: ${p.current}
'''),
      if (browserAggregation)
        d.file(customBuildYaml ? 'build.custom.yaml' : 'build.yaml', '''targets:
  \$default:
    builders:
      test_html_builder:
        options:
          browser_aggregation: true
'''),
      if (browserAggregation)
        d.file('dart_test.yaml', 'include: dart_test.browser_aggregate.yaml'),
      d.dir('test', [
        d.file('foo_test.dart', '''@TestOn('browser')
import 'package:test/test.dart';
void main() {
  test('passes', () {});
}
'''),
      ]),
    ]).create();
    return d.path('pkg');
  }

  Future<TestProcess> testBrowserAggregateExecutable(List<String> args,
      {String? workingDirectory}) async {
    final pubGet = await TestProcess.start('dart', ['pub', 'get'],
        workingDirectory: workingDirectory);
    await pubGet.shouldExit(0);
    return TestProcess.start(
        'dart', ['run', 'test_html_builder:browser_aggregate_tests', ...args],
        workingDirectory: workingDirectory);
  }

  test('--mode=args', () async {
    final dir = await createProject();
    final process = await testBrowserAggregateExecutable(['--mode=args'],
        workingDirectory: dir);
    expect(
        process.stdout,
        emitsInOrder([
          '--build-filter=test/templates/default_template.browser_aggregate_test.** -- --preset=browser-aggregate',
          emitsDone
        ]));
    await process.shouldExit(0);
  });

  test('--mode=args --release --build-args="-c custom"', () async {
    final dir = await createProject(customBuildYaml: true);
    final process = await testBrowserAggregateExecutable(
        ['--mode=args', '--release', '--build-args', '-c custom'],
        workingDirectory: dir);
    expect(
        process.stdout,
        emitsInOrder([
          '--build-filter=test/templates/default_template.browser_aggregate_test.** -- --preset=browser-aggregate',
          emitsDone
        ]));
    await process.shouldExit(0);
  });

  test('--mode=build', () async {
    final dir = await createProject();
    final process = await testBrowserAggregateExecutable(['--mode=build'],
        workingDirectory: dir);
    expect(
        process.stdout,
        emitsInOrder([
          emitsThrough('Building browser aggregate test config...'),
          emitsThrough(
              'dart run build_runner build --delete-conflicting-outputs --build-filter=dart_test.browser_aggregate.yaml'),
          emitsThrough(contains('Succeeded')),
          emitsThrough('Reading browser aggregate test config...'),
          emitsThrough('Found 1 aggregate tests to run.'),
          emitsThrough(
              'dart run build_runner build --build-filter=test/templates/default_template.browser_aggregate_test.**'),
          emitsThrough(contains('Succeeded')),
        ]));
    await process.shouldExit(0);
  });

  test('--mode=build --release --build-args="-c custom"', () async {
    final dir = await createProject(customBuildYaml: true);
    final process = await testBrowserAggregateExecutable(
        ['--mode=build', '--release', '--build-args', '-c custom'],
        workingDirectory: dir);
    expect(
        process.stdout,
        emitsInOrder([
          emitsThrough('Building browser aggregate test config...'),
          emitsThrough(
              'dart run build_runner build --delete-conflicting-outputs -c custom --build-filter=dart_test.browser_aggregate.yaml'),
          emitsThrough(contains('Succeeded')),
          emitsThrough('Reading browser aggregate test config...'),
          emitsThrough('Found 1 aggregate tests to run.'),
          emitsThrough(
              'dart run build_runner build -c custom --release --build-filter=test/templates/default_template.browser_aggregate_test.**'),
          emitsThrough(contains('Succeeded')),
        ]));
    await process.shouldExit(0);
  });

  test('--mode=test', () async {
    final dir = await createProject();
    // --mode=test is the default
    final process =
        await testBrowserAggregateExecutable([], workingDirectory: dir);
    expect(
        process.stdout,
        emitsInOrder([
          emitsThrough('Building browser aggregate test config...'),
          emitsThrough(
              'dart run build_runner build --delete-conflicting-outputs --build-filter=dart_test.browser_aggregate.yaml'),
          emitsThrough(contains('Succeeded')),
          emitsThrough('Reading browser aggregate test config...'),
          emitsThrough('Found 1 aggregate tests to run.'),
          emitsThrough(
              'dart run build_runner test --build-filter=test/templates/default_template.browser_aggregate_test.** -- --preset=browser-aggregate'),
          emitsThrough(contains('All tests passed!')),
        ]));
    await process.shouldExit(0);
  });

  test('--mode=test --build-args="--release -c custom"', () async {
    final dir = await createProject(customBuildYaml: true);
    // --mode=test is the default
    final process = await testBrowserAggregateExecutable(
        ['--build-args', '--release -c custom'],
        workingDirectory: dir);
    expect(
        process.stdout,
        emitsInOrder([
          emitsThrough('Building browser aggregate test config...'),
          emitsThrough(
              'dart run build_runner build --delete-conflicting-outputs --release -c custom --build-filter=dart_test.browser_aggregate.yaml'),
          emitsThrough(contains('Succeeded')),
          emitsThrough('Reading browser aggregate test config...'),
          emitsThrough('Found 1 aggregate tests to run.'),
          emitsThrough(
              'dart run build_runner test --release -c custom --build-filter=test/templates/default_template.browser_aggregate_test.** -- --preset=browser-aggregate'),
          emitsThrough(contains('All tests passed!')),
        ]));
    await process.shouldExit(0);
  });

  test('warns when browser aggregation is not enabled', () async {
    final dir = await createProject(browserAggregation: false);
    final process = await testBrowserAggregateExecutable(['--mode=args'],
        workingDirectory: dir);
    expect(
        process.stdout,
        emits(contains(
            'browser aggregation is not enabled. Update your build.yaml')));
    await process.shouldExit(isNot(0));
  });
}
