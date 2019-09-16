import 'package:build/build.dart';
import 'package:json_annotation/json_annotation.dart';

import 'package:test_html_builder/src/builder.dart';
import 'package:test_html_builder/src/config.dart';

TestHtmlBuilder testHtmlBuilder(BuilderOptions options) {
  try {
    final config = TestHtmlBuilderConfig.fromJson(options.config);
    for (final path in config.templates.keys) {
      if (!path.startsWith('./test/') && !path.startsWith('test/')) {
        throw StateError('Invalid template path: $path\n'
            'Every test html template must be located in the `test/` directory.');
      }
    }
    return TestHtmlBuilder(config);
  } on CheckedFromJsonException catch (e) {
    final lines = <String>[
      'Could not parse the options provided for `test_html_builder`.'
    ];

    if (e.key != null) {
      lines.add('There is a problem with "${e.key}".');
    }
    if (e.message != null) {
      lines.add(e.message);
    } else if (e.innerError != null) {
      lines.add(e.innerError.toString());
    }

    throw StateError(lines.join('\n'));
  }
}
