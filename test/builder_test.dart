@TestOn('vm')
import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:logging/logging.dart';
import 'package:test/test.dart';

import 'package:test_html_builder/builder.dart';
import 'package:test_html_builder/src/builder.dart';
import 'package:test_html_builder/src/config.dart';

void main() {
  group('testHtmlBuilder factory', () {
    test('returns TestHtmlBuilder', () {
      final options = BuilderOptions({
        'templates': {
          'test/bar_template.html': ['test/bar/**_test.dart'],
          'test/foo_template.html': ['**', 'foo'],
        },
      });
      final builder = testHtmlBuilder(options);
      expect(builder, isNotNull);
      expect(
          builder.getTemplateId(makeAssetId('a|test/bar/bar_test.dart')).path,
          'test/bar_template.html');
      expect(builder.getTemplateId(makeAssetId('a|test/foo_test.dart')).path,
          'test/foo_template.html');
    });

    test('throws StateError if any template is not in `test/`', () {
      final options = BuilderOptions({
        'templates': {
          'lib/bad_template.html': ['test/**_test.dart'],
        }
      });
      expect(
          () => testHtmlBuilder(options),
          throwsA(isA<StateError>().having(
              (e) => e.message, 'message', contains('lib/bad_template.html'))));
    });

    test('throws StateError if unsupported option key is provided', () {
      final options = BuilderOptions({
        'badkey': 'foo',
      });
      expect(() => testHtmlBuilder(options), throwsStateError);
    });

    test('throws StateError if templates format is invalid', () {
      final options = BuilderOptions({
        'templates': ['invalid format'],
      });
      expect(() => testHtmlBuilder(options), throwsStateError);
    });
  });

  group('TestHtmlBuilder', () {
    test('does nothing if no templates defined', () async {
      final config = TestHtmlBuilderConfig();
      final builder = TestHtmlBuilder(config);
      await testBuilder(builder, {
        'a|test/foo_test.dart': '',
        'a|test/template.html': '<html><head>{test}</head></html>',
      }, outputs: {});
    });

    test('does nothing if template does not match asset', () async {
      final config = TestHtmlBuilderConfig(templates: {
        'test/template.html': ['test/no_match.dart'],
      });
      final builder = TestHtmlBuilder(config);
      await testBuilder(builder, {
        'a|test/foo_test.dart': '',
        'a|test/template.html': '<html><head>{test}</head></html>',
      }, outputs: {});
    });

    test('outputs .html if template matches asset', () async {
      final config = TestHtmlBuilderConfig(templates: {
        'test/template.html': ['test/**_test.dart'],
      });
      final builder = TestHtmlBuilder(config);
      await testBuilder(builder, {
        'a|test/bar_test.dart': '',
        'a|test/foo_test.dart': '',
        'a|test/template.html': '<html><head>{test}</head></html>',
      }, outputs: {
        'a|test/bar_test.html':
            '''<html><head><link rel="x-dart-test" href="bar_test.dart"><script src="packages/test/dart.js"></script></head></html>''',
        'a|test/foo_test.html':
            '''<html><head><link rel="x-dart-test" href="foo_test.dart"><script src="packages/test/dart.js"></script></head></html>''',
      });
    });

    test('chooses first template that matches asset if multiple match',
        () async {
      final config = TestHtmlBuilderConfig(templates: {
        'test/a_template.html': ['test/bar_test.dart'],
        'test/b_template.html': ['test/**_test.dart'],
      });
      final builder = TestHtmlBuilder(config);
      await testBuilder(builder, {
        'a|test/bar_test.dart': '',
        'a|test/foo_test.dart': '',
        'a|test/a_template.html': '<html><head><!-- A -->{test}</head></html>',
        'a|test/b_template.html': '<html><head><!-- B -->{test}</head></html>',
      }, outputs: {
        'a|test/bar_test.html':
            '''<html><head><!-- A --><link rel="x-dart-test" href="bar_test.dart"><script src="packages/test/dart.js"></script></head></html>''',
        'a|test/foo_test.html':
            '''<html><head><!-- B --><link rel="x-dart-test" href="foo_test.dart"><script src="packages/test/dart.js"></script></head></html>''',
      });
    });

    test('copies .custom.html asset if found', () async {
      final config = TestHtmlBuilderConfig(templates: {
        'test/template.html': ['test/**_test.dart'],
      });
      final builder = TestHtmlBuilder(config);
      await testBuilder(builder, {
        'a|test/bar_test.dart': '',
        'a|test/bar_test.custom.html': 'CUSTOM BAR TEST',
        'a|test/foo_test.dart': '',
        'a|test/foo_test.custom.html': 'CUSTOM FOO TEST',
        'a|test/template.html': '<html><head>{test}</head></html>',
      }, outputs: {
        'a|test/bar_test.html': 'CUSTOM BAR TEST',
        'a|test/foo_test.html': 'CUSTOM FOO TEST',
      });
    });

    test('logs SEVERE if template cannot be read', () async {
      Logger.root.level = Level.ALL;
      expect(
          Logger.root.onRecord,
          emitsThrough(predicate<LogRecord>((record) =>
              record.message.contains('Could not read template') &&
              record.message.contains('test/template.html') &&
              record.level == Level.SEVERE)));

      final config = TestHtmlBuilderConfig(templates: {
        'test/template.html': ['test/**_test.dart'],
      });
      final builder = TestHtmlBuilder(config);
      await testBuilder(builder, {
        'a|test/foo_test.dart': '',
      });
    });

    test('logs SEVERE if template does not contain `{test}` token', () async {
      Logger.root.level = Level.ALL;
      expect(
          Logger.root.onRecord,
          emitsThrough(predicate<LogRecord>((record) =>
              record.message.contains('template must contain a `{test}`') &&
              record.message.contains('test/template.html') &&
              record.level == Level.SEVERE)));

      final config = TestHtmlBuilderConfig(templates: {
        'test/template.html': ['test/**_test.dart'],
      });
      final builder = TestHtmlBuilder(config);
      await testBuilder(builder, {
        'a|test/foo_test.dart': '',
        'a|test/template.html': 'MISSING TOKEN',
      });
    });
  });
}
