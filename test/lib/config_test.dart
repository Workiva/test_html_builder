@TestOn('vm')
import 'package:build/build.dart';
import 'package:test/test.dart';
import 'package:test_html_builder/src/config.dart';

void main() {
  group('TestHtmlBuilderConfig', () {
    test('with default values', () {
      final options = BuilderOptions({});
      final config = TestHtmlBuilderConfig.fromBuilderOptions(options);
      expect(config.browserAggregation, isFalse);
      expect(config.randomizeOrderingSeed, isNull);
      expect(config.templateGlobs, isEmpty);
    });

    test('with overrides', () {
      final options = BuilderOptions({
        'browser_aggregation': true,
        'randomize_ordering_seed': 'random',
        'templates': {
          'test/foo_template.html': ['test/**_test.dart'],
        }
      });
      final config = TestHtmlBuilderConfig.fromBuilderOptions(options);
      expect(config.browserAggregation, isTrue);
      expect(config.randomizeOrderingSeed, 'random');
      expect(config.templates, {
        'test/foo_template.html': ['test/**_test.dart'],
      });
      expect(
          config.templateGlobs['test/foo_template.html'].first
              .matches('test/foo_test.dart'),
          isTrue);
    });

    test('throws StateError if any templates are not in test/', () {
      final options = BuilderOptions({
        'templates': {
          'lib/bad_template.html': ['test/**_test.dart'],
        }
      });
      expect(
          () => TestHtmlBuilderConfig.fromBuilderOptions(options),
          throwsA(isA<StateError>().having(
              (e) => e.message, 'message', contains('lib/bad_template.html'))));
    });

    test('throws StateError if unsupported option key is provided', () {
      final options = BuilderOptions({
        'badkey': 'foo',
      });
      expect(() => TestHtmlBuilderConfig.fromBuilderOptions(options),
          throwsStateError);
    });

    test('throws StateError if templates format is invalid', () {
      final options = BuilderOptions({
        'templates': ['invalid format'],
      });
      expect(() => TestHtmlBuilderConfig.fromBuilderOptions(options),
          throwsStateError);
    });
  });
}
