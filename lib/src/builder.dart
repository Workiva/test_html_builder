import 'package:build/build.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;

import 'package:test_html_builder/src/config.dart';

const _inputExtension = '_test.dart';
const _outputExtension = '_test.html';

final _log = Logger('TestHtmlBuilder');

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

    htmlContents = htmlContents.replaceFirst(
        '{test}',
        '<link rel="x-dart-test" href="${p.basename(buildStep.inputId.path)}">'
            '<script src="packages/test/dart.js"></script>');
    await buildStep.writeAsString(htmlId, htmlContents);
  }
}
