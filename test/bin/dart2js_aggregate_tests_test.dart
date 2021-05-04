@TestOn('vm')
@Timeout(Duration(minutes: 1))
import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:test_descriptor/test_descriptor.dart' as d;
import 'package:test_process/test_process.dart';

void main() {
  Future<String> createProject({bool dart2jsAggregation}) async {
    dart2jsAggregation ??= true;
    await d.dir('pkg', [
      d.file('pubspec.yaml', '''name: pkg
environment:
  sdk: '>=2.7.2 <3.0.0'
dev_dependencies:
  build_runner: any
  build_test: any
  build_web_compilers: any
  test: any
  test_html_builder:
    path: ${p.current}
'''),
      if (dart2jsAggregation) d.file('build.yaml', '''targets:
  \$default:
    builders:
      test_html_builder:
        options:
          dart2js_aggregation: true
'''),
      if (dart2jsAggregation)
        d.file(
            'dart_test.yaml', 'include: test/dart_test.dart2js_aggregate.yaml'),
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

  Future<TestProcess> testDart2jsAggregateExecutable(List<String> args,
      {String workingDirectory}) async {
    final pubGet = await TestProcess.start('pub', ['get'],
        workingDirectory: workingDirectory);
    await pubGet.shouldExit(0);
    return TestProcess.start(
        'pub', ['run', 'test_html_builder:dart2js_aggregate_tests', ...args],
        workingDirectory: workingDirectory);
  }

  test('--mode=args', () async {
    final dir = await createProject();
    final process = await testDart2jsAggregateExecutable(['--mode=args'],
        workingDirectory: dir);
    expect(
        process.stdout,
        emitsInOrder([
          '--release --build-filter=test/templates/default_template.dart2js_aggregate_test.** -- --preset=dart2js-aggregate',
          emitsDone
        ]));
    await process.shouldExit(0);
  });

  test('--mode=build', () async {
    final dir = await createProject();
    final process = await testDart2jsAggregateExecutable(['--mode=build'],
        workingDirectory: dir);
    expect(
        process.stdout,
        emitsInOrder([
          emitsThrough('Building dart2js aggregate test config...'),
          emitsThrough(
              'pub run build_runner build --build-filter=test/dart_test.dart2js_aggregate.yaml'),
          emitsThrough(contains('Succeeded')),
          emitsThrough('Reading dart2js aggregate test config...'),
          emitsThrough('Found 1 aggregate tests to run.'),
          emitsThrough(
              'pub run build_runner build --release --build-filter=test/templates/default_template.dart2js_aggregate_test.**'),
          emitsThrough(contains('Succeeded')),
        ]));
    await process.shouldExit(0);
  });

  test('--mode=test', () async {
    final dir = await createProject();
    // --mode=test is the default
    final process =
        await testDart2jsAggregateExecutable([], workingDirectory: dir);
    expect(
        process.stdout,
        emitsInOrder([
          emitsThrough('Building dart2js aggregate test config...'),
          emitsThrough(
              'pub run build_runner build --build-filter=test/dart_test.dart2js_aggregate.yaml'),
          emitsThrough(contains('Succeeded')),
          emitsThrough('Reading dart2js aggregate test config...'),
          emitsThrough('Found 1 aggregate tests to run.'),
          emitsThrough(
              'pub run build_runner test --release --build-filter=test/templates/default_template.dart2js_aggregate_test.** -- --preset=dart2js-aggregate'),
          emitsThrough(contains('All tests passed!')),
        ]));
    await process.shouldExit(0);
  });

  test('debug', () async {
    final dir = await createProject();
    final process = await testDart2jsAggregateExecutable(
        ['--mode=args', '--debug'],
        workingDirectory: dir);
    expect(
        process.stdout,
        emitsInOrder([
          '--build-filter=test/templates/default_template.dart2js_aggregate_test.** -- --preset=dart2js-aggregate',
          emitsDone
        ]));
    await process.shouldExit(0);
  });

  test('warns when dart2js aggregation is not enabled', () async {
    final dir = await createProject(dart2jsAggregation: false);
    final process = await testDart2jsAggregateExecutable(['--mode=args'],
        workingDirectory: dir);
    expect(
        process.stdout,
        emits(contains(
            'dart2js aggregation is not enabled. Update your build.yaml')));
    await process.shouldExit(isNot(0));
  });
}
