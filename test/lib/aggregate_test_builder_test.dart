@TestOn('vm')
import 'dart:convert';

import 'package:build_test/build_test.dart';
import 'package:test/test.dart';
import 'package:test_html_builder/src/builder.dart';
import 'package:test_html_builder/src/config.dart';

void main() {
  group('AggregateTestBuilder', () {
    test('does nothing if dart2js aggregate not enabled', () async {
      final config = TestHtmlBuilderConfig(templates: {
        'test/foo_template.html': ['test/foo_test.dart'],
      });
      final builder = AggregateTestBuilder();
      await testBuilder(builder, {
        'a|test/test_html_builder_config.json': jsonEncode(config),
        'a|test/foo_test.dart': '',
        'a|test/foo_template.html': '<html><head>{{testScript}}</head></html>',
      }, outputs: {});
    });

    test('generates an aggregate test for each template', () async {
      final config =
          TestHtmlBuilderConfig(dart2jsAggregation: true, templates: {
        'test/templates/foo_template.html': ['test/foo_test.dart'],
        'test/templates/bar_template.html': ['test/bar_test.dart'],
      });
      final builder = AggregateTestBuilder();
      await testBuilder(builder, {
        'a|test/test_html_builder_config.json': jsonEncode(config),
        'a|test/vm_test.dart': "@TestOn('vm') library vm_test;",
        'a|test/foo_test.dart': '',
        'a|test/bar_test.dart': '',
        'a|test/templates/foo_template.html': '',
        'a|test/templates/bar_template.html': '',
      }, outputs: {
        'a|test/templates/foo_template.dart2js_aggregate_test.dart':
            '''@TestOn('browser')
import 'package:test/test.dart';

import '../foo_test.dart' as foo_test;

void main() {
  foo_test.main();
}
''',
        'a|test/templates/bar_template.dart2js_aggregate_test.dart':
            '''@TestOn('browser')
import 'package:test/test.dart';

import '../bar_test.dart' as bar_test;

void main() {
  bar_test.main();
}
'''
      });
    });

    test('generates a default aggregate test for browser tests', () async {
      final config =
          TestHtmlBuilderConfig(dart2jsAggregation: true, templates: {
        'test/templates/foo_template.html': ['test/foo_test.dart'],
        'test/templates/bar_template.html': ['test/bar_test.dart'],
      });
      final builder = AggregateTestBuilder();
      await testBuilder(builder, {
        'a|test/test_html_builder_config.json': jsonEncode(config),
        'a|test/templates/default_template.html': '',
        'a|test/templates/foo_template.html': '',
        'a|test/templates/bar_template.html': '',
        'a|test/vm_test.dart': "@TestOn('vm') library vm_test;",
        'a|test/other_test.dart': '',
      }, outputs: {
        'a|test/templates/default_template.dart2js_aggregate_test.dart':
            '''@TestOn('browser')
import 'package:test/test.dart';

import '../other_test.dart' as other_test;

void main() {
  other_test.main();
}
'''
      });
    });

    test('if multiple templates match, chooses first one', () async {
      final config =
          TestHtmlBuilderConfig(dart2jsAggregation: true, templates: {
        'test/templates/foo_template.html': ['test/**_test.dart'],
        'test/templates/bar_template.html': ['test/**_test.dart'],
      });
      final builder = AggregateTestBuilder();
      await testBuilder(builder, {
        'a|test/test_html_builder_config.json': jsonEncode(config),
        'a|test/foo_test.dart': '',
        'a|test/bar_test.dart': '',
        'a|test/templates/foo_template.html': '',
        'a|test/templates/bar_template.html': '',
      }, outputs: {
        'a|test/templates/foo_template.dart2js_aggregate_test.dart':
            '''@TestOn('browser')
import 'package:test/test.dart';

import '../foo_test.dart' as foo_test;
import '../bar_test.dart' as bar_test;

void main() {
  foo_test.main();
  bar_test.main();
}
'''
      });
    });
  });
}
