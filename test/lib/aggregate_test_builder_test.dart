@TestOn('vm')
import 'dart:convert';

import 'package:build_test/build_test.dart';
import 'package:test/test.dart';
import 'package:test_html_builder/src/builder.dart';
import 'package:test_html_builder/src/config.dart';

void main() {
  group('AggregateTestBuilder', () {
    test('does nothing if browser aggregate not enabled', () async {
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
          TestHtmlBuilderConfig(browserAggregation: true, templates: {
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
        'a|test/templates/foo_template.browser_aggregate_test.dart':
            '''@TestOn('browser')
import 'package:test/test.dart';

import '../foo_test.dart' as foo_test;

void main() {
  foo_test.main();
}
''',
        'a|test/templates/bar_template.browser_aggregate_test.dart':
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
          TestHtmlBuilderConfig(browserAggregation: true, templates: {
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
        'a|test/a_test.dart': '',
        'a|test/b_test.dart': '',
      }, outputs: {
        'a|test/templates/default_template.browser_aggregate_test.dart':
            '''@TestOn('browser')
import 'package:test/test.dart';

import '../a_test.dart' as a_test;
import '../b_test.dart' as b_test;

void main() {
  a_test.main();
  b_test.main();
}
'''
      });
    });

    test('generates a default randomizes aggregate test for browser tests',
        () async {
      final config = TestHtmlBuilderConfig(
          browserAggregation: true,
          randomizeAggregation: true,
          testShuffleSeed: 2,
          templates: {
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
        'a|test/a_test.dart': '',
        'a|test/b_test.dart': '',
        'a|test/c_test.dart': '',
        'a|test/d_test.dart': '',
        'a|test/e_test.dart': '',
      }, outputs: {
        'a|test/templates/default_template.browser_aggregate_test.dart': decodedMatches(allOf(
            contains('''@TestOn('browser')
import 'package:test/test.dart';

import '../a_test.dart' as a_test;
import '../b_test.dart' as b_test;
import '../c_test.dart' as c_test;
import '../d_test.dart' as d_test;
import '../e_test.dart' as e_test;
'''),
            isNot(contains('''
void main() {
  a_test.main();
  b_test.main();
  c_test.main();
  d_test.main();
  e_test.main();
}
'''))))
      });
    });

    test('if multiple templates match, chooses first one', () async {
      final config =
          TestHtmlBuilderConfig(browserAggregation: true, templates: {
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
        'a|test/templates/foo_template.browser_aggregate_test.dart':
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
