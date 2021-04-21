import 'dart:convert';

import 'package:build_test/build_test.dart';
import 'package:test/test.dart';
import 'package:test_html_builder/src/builder.dart';
import 'package:test_html_builder/src/config.dart';

void main() {
  group('DartTestYamlBuilder', () {
    test('does nothing if dart2js aggregate not enabled', () async {
      final config = TestHtmlBuilderConfig(dart2jsAggregation: false);
      final builder = DartTestYamlBuilder();
      await testBuilder(builder, {
        'a|test/test_html_builder_config.json': jsonEncode(config),
        'a|test/foo_template.dart2js_aggregate_test.dart': '',
        'a|test/foo_template.html': '',
      }, outputs: {});
    });

    test('generates a preset with a path for each aggregate test', () async {
      final config = TestHtmlBuilderConfig(dart2jsAggregation: true);
      final builder = DartTestYamlBuilder();
      await testBuilder(builder, {
        'a|test/test_html_builder_config.json': jsonEncode(config),
        'a|test/foo_template.dart2js_aggregate_test.dart': '',
        'a|test/foo_template.html': '',
        // This template should be found, but ignored because there is no
        // accompanying .dart2js_aggregate_test.dart
        'a|test/bar_template.html': '',
        // This test should get included because it has a custom HTML
        'a|test/custom_test.dart': '',
        'a|test/custom_test.custom.html': '',
      }, outputs: {
        'a|test/dart_test.dart2js_aggregate.yaml': '''presets:
  dart2js-aggregate:
    platforms: [chrome]
    paths:
      - test/foo_template.dart2js_aggregate_test.dart
      - test/custom_test.dart
'''
      });
    });
  });
}
