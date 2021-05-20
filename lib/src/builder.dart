// Copyright 2019 Workiva Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'dart:async';
import 'dart:convert';

import 'package:build/build.dart';
import 'package:dart_style/dart_style.dart';
import 'package:glob/glob.dart';
import 'package:path/path.dart' as p;
// This import is deprecated to discourage its use, but the build_test package
// uses it for the same reason we're using it here. So if they choose to get rid
// of this import, they'll presumably have a plan for a different way to
// accomplish the same thing that we can use.
// ignore: deprecated_member_use
import 'package:test_core/backend.dart'
    show Metadata, Runtime, SuitePlatform, parseMetadata;

import 'config.dart';

class TestHtmlBuilder implements Builder {
  TestHtmlBuilderConfig _config;

  TestHtmlBuilder(this._config);

  @override
  final buildExtensions = {
    r'$test$': [
      'templates/default_template.html',
      'test_html_builder_config.json',
    ]
  };

  @override
  Future<void> build(BuildStep buildStep) async {
    // Write the default template for any browser tests that don't match one of
    // the templates defined in the project's config.
    final defaultTemplateId = AssetId(
        buildStep.inputId.package, 'test/templates/default_template.html');
    await buildStep.writeAsString(defaultTemplateId, '''<!doctype html>
<html>
  <head>
    <title>{{testName}} Test</title>
    {{testScript}}
    <script src="packages/test/dart.js"></script>
  </head>
</html>
''');

    // Write the builder options so they can be used by the builders below.
    final configId = AssetId(
        buildStep.inputId.package, 'test/test_html_builder_config.json');
    await buildStep.writeAsString(configId, json.encode(_config));
  }
}

class AggregateTestBuilder extends Builder {
  @override
  final buildExtensions = const {
    '_template.html': ['_template.browser_aggregate_test.dart'],
  };

  @override
  Future<void> build(BuildStep buildStep) async {
    _config ??= await decodeConfig(buildStep);
    if (!_config.browserAggregation) {
      log.fine('browser aggregation disabled');
      return;
    }

    final templatePath = buildStep.inputId.path;
    final isDefault = templatePath == 'test/templates/default_template.html';
    final testGlobs = isDefault
        ? [Glob('test/**_test.dart')]
        : _config.templateGlobs[templatePath] ?? [];
    log.fine(
        'Test globs found for template: ${buildStep.inputId}:\n${testGlobs.join('\n')}');

    final higherPrecedenceGlobs = <Glob>[];
    if (isDefault) {
      // For the default template, all defined globs are higher precedence.
      for (final globs in _config.templateGlobs.values) {
        higherPrecedenceGlobs.addAll(globs);
      }
    } else {
      for (final t in _config.templateGlobs.keys) {
        // Only templates defined before the current one take precedence.
        if (t == templatePath) break;
        higherPrecedenceGlobs.addAll(_config.templateGlobs[t]);
      }
    }

    final imports = StringBuffer();
    final mains = StringBuffer();
    for (final glob in testGlobs) {
      await for (final id in buildStep.findAssets(glob)) {
        // If any of the template globs defined above this one match this test,
        // then it will be included in that aggregate test.
        if (higherPrecedenceGlobs.any((g) => g.matches(id.path))) continue;

        final hasCustomHtml =
            await buildStep.canRead(id.changeExtension('.custom.html'));
        if (hasCustomHtml) continue;

        Metadata testMetadata;
        try {
          testMetadata = parseMetadata(
              id.path, await buildStep.readAsString(id), _platformVariables);
        } catch (e, stack) {
          log.severe('Error parsing test metadata: ${id.path}', e, stack);
          continue;
        }

        if (!_isBrowserTest(testMetadata)) continue;

        final prefix = _importPrefixForTest(id.path);
        final path =
            p.relative(id.path, from: p.dirname(buildStep.inputId.path));
        imports.writeln("import '$path' as $prefix;");
        mains.writeln("  $prefix.main();");
      }
    }

    // Don't generate an empty aggregate test.
    if (imports.isEmpty) return;

    final contents = DartFormatter().format('''@TestOn('browser')
import 'package:test/test.dart';

$imports
void main() {
$mains}
''');

    final outputId =
        buildStep.inputId.changeExtension('.browser_aggregate_test.dart');
    await buildStep.writeAsString(outputId, contents);
  }

  final _browserRuntimes = Runtime.builtIn.where((r) => r.isBrowser == true);

  Set<String> get _platformVariables => [
        Runtime.vm,
        Runtime.nodeJS,
        ..._browserRuntimes,
      ].map((r) => r.identifier).toSet();

  String _importPrefixForTest(String path) {
    // Remove `test/` segment.
    var result = p.split(path).skip(1).join(p.separator);
    // Remove .dart extension and invalid characters for an import prefix.
    result = p.withoutExtension(result);
    return result.replaceAll(p.separator, '_').replaceAll('.', '_');
  }

  bool _isBrowserTest(Metadata testMetadata) => _browserRuntimes
      .any((r) => testMetadata.testOn.evaluate(SuitePlatform(r)));

  TestHtmlBuilderConfig _config;
}

/// Builder that uses templates to generate HTML files for dart tests.
///
/// Useful for projects with many tests that require custom HTML. Instead of
/// having to replicate the custom HTML file for every test file that requires
/// it, this builder can apply a template to any number of test files.
class TemplateBuilder implements Builder {
  @override
  final buildExtensions = {
    // This allows the builder to output an HTML file to be used by any Dart
    // test that matches one of the template globs.
    '_test.dart': ['_test.html'],
  };

  static AssetId getCustomHtmlId(AssetId assetId) =>
      assetId.changeExtension('.custom.html');

  static AssetId getHtmlId(AssetId assetId) => assetId.changeExtension('.html');

  AssetId getTemplateId(
      Map<String, Iterable<Glob>> templates, AssetId assetId) {
    if (assetId.path.endsWith('.browser_aggregate_test.dart')) {
      return AssetId(assetId.package,
          assetId.path.replaceFirst('.browser_aggregate_test.dart', '.html'));
    }

    for (final templatePath in templates.keys) {
      final globs = templates[templatePath];
      if (globs.any((glob) => glob.matches(assetId.path))) {
        return AssetId(assetId.package, templatePath);
      }
    }
    return null;
  }

  @override
  Future<void> build(BuildStep buildStep) async {
    final htmlId = getHtmlId(buildStep.inputId);
    final customHtmlId = getCustomHtmlId(buildStep.inputId);

    if (await buildStep.canRead(customHtmlId)) {
      log.fine('Custom html found for ${buildStep.inputId.path}');
      await buildStep.writeAsBytes(
          htmlId, await buildStep.readAsBytes(customHtmlId));
      return;
    }

    _config ??= await decodeConfig(buildStep);
    final templateId = getTemplateId(_config.templateGlobs, buildStep.inputId);
    if (templateId == null) {
      return;
    }
    if (!await buildStep.canRead(templateId)) {
      log.severe('Could not read template at ${templateId.path}');
      return;
    }

    log.fine(
        'Generating html for ${buildStep.inputId.path} from template at ${templateId.path}');
    var htmlContents = await buildStep.readAsString(templateId);
    if ('{{testScript}}'.allMatches(htmlContents).length != 1) {
      log.severe(
          'Test html template must contain exactly one `{{testScript}}` placeholder: ${templateId.path}');
      return;
    }

    final scriptBase = htmlEscape.convert(p.basename(buildStep.inputId.path));
    final link = '<link rel="x-dart-test" href="$scriptBase">';
    final testName = htmlEscape.convert(buildStep.inputId.path);
    htmlContents = htmlContents
        .replaceFirst('{{testScript}}', link)
        .replaceAll('{{testName}}', testName);
    await buildStep.writeAsString(htmlId, htmlContents);
  }

  TestHtmlBuilderConfig _config;
}

class DartTestYamlBuilder extends Builder {
  @override
  final buildExtensions = const {
    // TODO: once on latest Dart and build_runner, use this:
    // r'$package$': ['dart_test.browser_aggregate.yaml'],
    r'$test$': ['dart_test.browser_aggregate.yaml'],
  };

  @override
  Future<void> build(BuildStep buildStep) async {
    if (!(await decodeConfig(buildStep)).browserAggregation) {
      log.fine('browser aggregation disabled');
      return;
    }

    log.fine('Building test/dart_test.browser_aggregate.yaml');
    final contents = StringBuffer()..writeln('''presets:
  browser-aggregate:
    platforms: [chrome]
    paths:''');

    final aggregateTests = buildStep.findAssets(Glob('test/**_template.browser_aggregate_test.dart'));
    await for (final testId in aggregateTests) {
      log.fine('Found aggregate test: ${testId.path}');
      contents.writeln('      - ${testId.path}');
    }

    await for (final customHtml
        in buildStep.findAssets(Glob('test/**_test.custom.html'))) {
      log.fine('Found custom HTML test: ${customHtml.path}');
      final customTestPath =
          customHtml.path.replaceFirst('_test.custom.html', '_test.dart');
      contents.writeln('      - $customTestPath');
    }

    final outputId = AssetId(
        buildStep.inputId.package, 'test/dart_test.browser_aggregate.yaml');
    await buildStep.writeAsString(outputId, contents.toString());
  }
}

Future<TestHtmlBuilderConfig> decodeConfig(BuildStep buildStep) async {
  final id =
      AssetId(buildStep.inputId.package, 'test/test_html_builder_config.json');
  final contents = await buildStep.readAsString(id);
  return TestHtmlBuilderConfig.fromJson(json.decode(contents));
}
