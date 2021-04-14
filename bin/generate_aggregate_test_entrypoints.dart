import 'dart:io';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:build_config/build_config.dart';
import 'package:glob/glob.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;
// ignore: deprecated_member_use
import 'package:test_core/backend.dart'
    show Metadata, Runtime, SuitePlatform, parseMetadata;
import 'package:test_html_builder/src/config.dart';

final Iterable<Runtime> browserRuntimes =
    Runtime.builtIn.where((r) => r.isBrowser == true);

final platformVariables = [
  Runtime.vm,
  Runtime.nodeJS,
  ...browserRuntimes,
].map((r) => r.identifier).toSet();

const aggregatedTestsPath = 'test/_aggregated/';

final aggregateBrowserTestPath =
    p.join(aggregatedTestsPath, 'browser_test.dart');

String aggregateBrowserTestPathForTemplate(String templatePath) =>
    p.join(aggregatedTestsPath, '${varNameFromPath(templatePath)}_test.dart');

void main() async {
  // Find all `test/**_test.dart` files
  // For each:
  // - Parse AST
  // - If `TestOn()` annotation value does not include `browser`, exclude from
  //     aggregation
  // - Look for custom HTML template, exclude from aggregation if found (but
  //     store the path for later)
  // - Use test_html_builder config to find matching HTML template, xand add to
  //     bucket for that template if found
  // - Otherwise, add to a default no-custom-html bucket
  // Generate aggregate test entrypoint for each bucket
  // Generate `build.tests_release.yaml` config that only configures the
  //   `build_web_compilers|entrypoint` builder to the aggregate entry points
  //   and all of the individual tests with custom HTML
  final log = Logger('test_html_builder');

  // Parse the build.yaml for this package so we can use the `test_html_builder`
  // config to make decisions later.
  final config = await parseTestHtmlBuilderConfig();

  // Test files with @TestOn('browser') and no custom HTML. These will all be
  // aggregated into a single test entrypoint.
  final aggregatedBrowserTests = <String>{};

  // Browser test files that use one of the custom HTML templates specified in
  // the `test_html_builder` config. The key is the template path and the value
  // is the list of matching test files. An aggregate test entrypoint will be
  // created for each template bucket.
  final aggregatedBrowserTestsByTemplate =
      <String /* template */, Set<String /* test */ >>{};

  // Test files that don't fall into either of the above scenarios. These are
  // tests that either don't run on the browser (like VM tests), run on a more
  // specific platform (like only Chrome), or run on more than one platform
  // (like browser and VM). These tests will not be aggregated and will instead
  // be run individually like normal to ensure that they run in all of the
  // desired contexts.
  final individualBrowserTests = <String>{};

  var hasErrors = false;
  final tests = Glob('test/**_test.dart', recursive: true);
  for (final test in tests.listSync().whereType<File>()) {
    final testPath = p.relative(p.fromUri(test.uri));
    if (p.isWithin(aggregatedTestsPath, testPath)) continue;

    final testContents = test.readAsStringSync();

    Metadata testMetadata;
    try {
      testMetadata = parseMetadata(testPath, testContents, platformVariables);
    } catch (e, stack) {
      log.severe('Error parsing test metadata: $testPath', e, stack);
      hasErrors = true;
      continue;
    }

    // final testOn = getTestOnAnnotation(result.unit);
    // if (testMetadata.testOn.toString() == ) {
    //   log.severe('Test file must have a @TestOn() annotation: $testPath');
    //   hasErrors = true;
    //   continue;
    // }

    // TODO: for now, only supporting @TestOn('browser'), but in the future we
    // could try to support all permutations of platform selectors.
    if (isBrowserOnlyTest(testMetadata)) {
      final templatePath = getMatchingTestHtmlTemplate(config, testPath);
      if (templatePath != null) {
        aggregatedBrowserTestsByTemplate
            .putIfAbsent(templatePath, () => <String>{})
            .add(testPath);
      } else {
        aggregatedBrowserTests.add(testPath);
      }
    } else if (isBrowserTest(testMetadata)) {
      individualBrowserTests.add(testPath);
    }
  }

  if (hasErrors) {
    log.severe('The above errors must be fixed before aggregate test '
        'entrypoints can be generated and run.');
    exitCode = 1;
    return;
  }
  final buildYaml = generateBuildYaml([
    ...aggregatedBrowserTests,
    for (final templatePath in aggregatedBrowserTestsByTemplate.keys)
      aggregateBrowserTestPathForTemplate(templatePath),
    ...individualBrowserTests,
  ], aggregatedBrowserTestsByTemplate);

  File('build._aggregated_test.yaml').writeAsStringSync(buildYaml);
  Directory(aggregatedTestsPath).createSync();

  if (aggregatedBrowserTests.isNotEmpty) {
    final test =
        generateAggregateTestEntrypoint('browser', aggregatedBrowserTests);
    File(aggregateBrowserTestPath).writeAsStringSync(test);
  }

  for (final templatePath in aggregatedBrowserTestsByTemplate.keys) {
    final testPath = aggregateBrowserTestPathForTemplate(templatePath);
    final test = generateAggregateTestEntrypoint(
        'browser', aggregatedBrowserTestsByTemplate[templatePath]);
    File(testPath).writeAsStringSync(test);
  }
}

bool isBrowserTest(Metadata testMetadata) =>
    browserRuntimes.any((r) => testMetadata.testOn.evaluate(SuitePlatform(r)));

bool isBrowserOnlyTest(Metadata testMetadata) =>
    testMetadata.testOn.toString() == 'browser';

String generateAggregateTestEntrypoint(
    String platformSelector, Iterable<String> tests) {
  final testOn = "@TestOn('$platformSelector')";

  final imports = StringBuffer();
  final mainInvocations = StringBuffer();
  for (final test in tests) {
    final name = varNameFromPath(test);
    final path = p.relative(test, from: aggregatedTestsPath);
    imports.writeln("import '$path' as $name;");
    mainInvocations.writeln("  $name.main();");
  }

  return '''$testOn

import 'package:test/test.dart';

$imports

void main() {
$mainInvocations}
''';
}

String generateBuildYaml(
  Iterable<String> browserTests,
  Map<String, Iterable<String>> testsByTemplate,
) {
  final b = StringBuffer();

  b.writeln('''targets:
  \$default:
    builders:
      build_web_compilers|entrypoint:
        release_options:
          dart2js_args:
            - --no-minify
        generate_for:
          include:''');
  for (final test in browserTests) {
    b.writeln('            - "$test**"'); // TODO: more specific?
  }

  b.writeln('''
      test_html_builder:
        options:
          templates:''');
  for (final templatePath in testsByTemplate.keys) {
    b.writeln('            "$templatePath":');
    for (final testPath in testsByTemplate[templatePath]) {
      b.writeln('              - "$testPath"');
    }
  }

  return b.toString();
}

String getMatchingTestHtmlTemplate(
    TestHtmlBuilderConfig config, String testPath) {
  for (final templatePath in config.templateGlobs.keys) {
    if (config.templateGlobs[templatePath]
        .any((glob) => glob.matches(testPath))) {
      return templatePath;
    }
  }
  return null;
}

ElementAnnotation getTestOnAnnotation(CompilationUnit unit) {
  return unit.declaredElement.library.metadata.firstWhere(
      (annotation) => annotation.element?.name == 'TestOn',
      orElse: () => null);
}

bool isTestOnBrowser(ElementAnnotation annotation) {
  return annotation.constantValue.toStringValue() == 'browser';
}

bool isPart(CompilationUnit unit) =>
    unit.directives.any((directive) => directive is PartOfDirective);

Future<TestHtmlBuilderConfig> parseTestHtmlBuilderConfig() async {
  final buildConfig = await BuildConfig.fromPackageDir('.');
  // TODO: actually find default target using current package name
  final buildTarget =
      buildConfig.buildTargets['permissions_editor:permissions_editor'];
  final testHtmlBuilderConfig =
      (buildTarget?.builders ?? {})['test_html_builder:test_html_builder'];
  final testHtmlBuilderOptions =
      BuilderOptions(testHtmlBuilderConfig?.options ?? {}).overrideWith(
          BuilderOptions(testHtmlBuilderConfig?.releaseOptions ?? {}));
  return TestHtmlBuilderConfig.fromJson(testHtmlBuilderOptions.config);
}

String varNameFromPath(String path) =>
    p.withoutExtension(path).replaceAll(p.separator, '_').replaceAll('.', '_');
