// @dart = 2.7

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

import 'package:build/build.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;

import 'package:test_html_builder/src/config.dart';

const _inputExtension = '_test.dart';
const _outputExtension = '_test.html';

final _log = Logger('TestHtmlBuilder');

/// Builder that uses templates to generate HTML files for dart tests.
///
/// Useful for projects with many tests that require custom HTML. Instead of
/// having to replicate the custom HTML file for every test file that requires
/// it, this builder can apply a template to any number of test files.
class TestHtmlBuilder implements Builder {
  TestHtmlBuilderConfig _config;

  TestHtmlBuilder(this._config);

  @override
  final buildExtensions = const {
    _inputExtension: [_outputExtension],
  };

  static AssetId getCustomHtmlId(AssetId assetId) =>
      assetId.changeExtension('.custom.html');

  static AssetId getHtmlId(AssetId assetId) => assetId.changeExtension('.html');

  AssetId getTemplateId(AssetId assetId) {
    for (final templatePath in _config.templateGlobs.keys) {
      final globs = _config.templateGlobs[templatePath];
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
      _log.fine('Custom html found for ${buildStep.inputId.path}');
      await buildStep.writeAsBytes(
          htmlId, await buildStep.readAsBytes(customHtmlId));
      return;
    }

    final templateId = getTemplateId(buildStep.inputId);
    if (templateId == null) {
      return;
    }
    if (!await buildStep.canRead(templateId)) {
      _log.severe('Could not read template at ${templateId.path}');
      return;
    }

    _log.fine(
        'Generating html for ${buildStep.inputId.path} from template at ${templateId.path}');
    var htmlContents = await buildStep.readAsString(templateId);
    if (!htmlContents.contains('{test}')) {
      _log.severe(
          'Test html template must contain a `{test}` token: ${templateId.path}');
      return;
    }

    htmlContents = htmlContents.replaceAll(
        '{test}',
        '<link rel="x-dart-test" href="${p.basename(buildStep.inputId.path)}">'
            '<script src="packages/test/dart.js"></script>');
    await buildStep.writeAsString(htmlId, htmlContents);
  }
}
