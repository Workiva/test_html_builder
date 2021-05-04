@TestOn('vm')
import 'dart:convert';

import 'package:build_test/build_test.dart';
import 'package:test/test.dart';
import 'package:test_html_builder/src/builder.dart';
import 'package:test_html_builder/src/config.dart';

void main() {
  test('TestHtmlBuilder', () async {
    final config = TestHtmlBuilderConfig(templates: {
      'test/template.html': ['test/foo_test.dart'],
    });
    final builder = TestHtmlBuilder(config);
    await testBuilder(builder, {
      r'a|test/$test$': '',
    }, outputs: {
      'a|test/templates/default_template.html': '''<!doctype html>
<html>
  <head>
    <title>{{testName}} Test</title>
    {{testScript}}
    <script src="packages/test/dart.js"></script>
  </head>
</html>
''',
      'a|test/test_html_builder_config.json': jsonEncode(config),
    });
  });
}
