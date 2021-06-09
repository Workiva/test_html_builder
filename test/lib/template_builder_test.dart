// @dart=2.7
// ^ Do not remove until migrated to null safety. More info at https://wiki.atl.workiva.net/pages/viewpage.action?pageId=189370832
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

@TestOn('vm')
import 'dart:convert';

import 'package:build_test/build_test.dart';
import 'package:test/test.dart';

import 'package:test_html_builder/src/builder.dart';
import 'package:test_html_builder/src/config.dart';

void main() {
  group('TemplateBuilder', () {
    test('does nothing if no templates defined', () async {
      final builder = TemplateBuilder();
      await testBuilder(builder, {
        'a|test/test_html_builder_config.json': '{}',
        'a|test/foo_test.dart': '',
        'a|test/template.html': '<html><head>{{testScript}}</head></html>',
      }, outputs: {});
    });

    test('does nothing if template does not match asset', () async {
      final config = TestHtmlBuilderConfig(templates: {
        'test/template.html': ['test/no_match.dart'],
      });
      final builder = TemplateBuilder();
      await testBuilder(builder, {
        'a|test/test_html_builder_config.json': jsonEncode(config),
        'a|test/foo_test.dart': '',
        'a|test/template.html': '<html><head>{{testScript}}</head></html>',
      }, outputs: {});
    });

    test('outputs .html if template matches asset', () async {
      final config = TestHtmlBuilderConfig(templates: {
        'test/template.html': ['test/**_test.dart'],
      });
      final builder = TemplateBuilder();
      await testBuilder(builder, {
        'a|test/test_html_builder_config.json': jsonEncode(config),
        'a|test/bar_test.dart': '',
        'a|test/foo_test.dart': '',
        'a|test/template.html': '<html><head>{{testScript}}</head></html>',
      }, outputs: {
        'a|test/bar_test.html':
            '''<html><head><link rel="x-dart-test" href="bar_test.dart"></head></html>''',
        'a|test/foo_test.html':
            '''<html><head><link rel="x-dart-test" href="foo_test.dart"></head></html>''',
      });
    });

    test('chooses first template that matches asset if multiple match',
        () async {
      final config = TestHtmlBuilderConfig(templates: {
        'test/a_template.html': ['test/bar_test.dart'],
        'test/b_template.html': ['test/**_test.dart'],
      });
      final builder = TemplateBuilder();
      await testBuilder(builder, {
        'a|test/test_html_builder_config.json': jsonEncode(config),
        'a|test/bar_test.dart': '',
        'a|test/foo_test.dart': '',
        'a|test/a_template.html':
            '<html><head><!-- A -->{{testScript}}</head></html>',
        'a|test/b_template.html':
            '<html><head><!-- B -->{{testScript}}</head></html>',
      }, outputs: {
        'a|test/bar_test.html':
            '''<html><head><!-- A --><link rel="x-dart-test" href="bar_test.dart"></head></html>''',
        'a|test/foo_test.html':
            '''<html><head><!-- B --><link rel="x-dart-test" href="foo_test.dart"></head></html>''',
      });
    });

    test('copies .custom.html asset if found', () async {
      final config = TestHtmlBuilderConfig(templates: {
        'test/template.html': ['test/**_test.dart'],
      });
      final builder = TemplateBuilder();
      await testBuilder(builder, {
        'a|test/test_html_builder_config.json': jsonEncode(config),
        'a|test/bar_test.dart': '',
        'a|test/bar_test.custom.html': 'CUSTOM BAR TEST',
        'a|test/foo_test.dart': '',
        'a|test/foo_test.custom.html': 'CUSTOM FOO TEST',
        'a|test/template.html': '<html><head>{{testScript}}</head></html>',
      }, outputs: {
        'a|test/bar_test.html': 'CUSTOM BAR TEST',
        'a|test/foo_test.html': 'CUSTOM FOO TEST',
      });
    });

    test('logs SEVERE if template cannot be read', () async {
      final config = TestHtmlBuilderConfig(templates: {
        'test/template.html': ['test/**_test.dart'],
      });
      final builder = TemplateBuilder();
      final logs = recordLogs(() => testBuilder(builder, {
            'a|test/test_html_builder_config.json': jsonEncode(config),
            'a|test/foo_test.dart': '',
          }));
      expect(
          logs,
          emits(severeLogOf(allOf(
            contains('Could not read template'),
            contains('test/template.html'),
          ))));
    });

    test('logs SEVERE if template does not contain `{test}` token', () async {
      final config = TestHtmlBuilderConfig(templates: {
        'test/template.html': ['test/**_test.dart'],
      });
      final builder = TemplateBuilder();
      final logs = recordLogs(() => testBuilder(builder, {
            'a|test/test_html_builder_config.json': jsonEncode(config),
            'a|test/foo_test.dart': '',
            'a|test/template.html': 'MISSING TOKEN',
          }));
      expect(
          logs,
          emits(severeLogOf(allOf(
            contains('template must contain exactly one `{{testScript}}`'),
            contains('test/template.html'),
          ))));
    });
  });
}
