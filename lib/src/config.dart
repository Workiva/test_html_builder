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

// If changes are made to this class and regeneration is needed, uncomment the
// json_annotation and json_serializable dependencies in pubspec.yaml, and then
// comment out the test_html_builder definition in `build.yaml`.
library lib.src.config;

import 'package:build/build.dart';
import 'package:glob/glob.dart';
import 'package:json_annotation/json_annotation.dart';

part 'config.g.dart';

@JsonSerializable(
    anyMap: true,
    checked: true,
    disallowUnrecognizedKeys: true,
    fieldRename: FieldRename.snake)
class TestHtmlBuilderConfig {
  TestHtmlBuilderConfig(
      {bool? browserAggregation,
      String? randomizeOrderingSeed,
      Map<String, List<String>>? templates})
      : browserAggregation = browserAggregation ?? false,
        randomizeOrderingSeed = randomizeOrderingSeed,
        templates = templates ?? {};

  factory TestHtmlBuilderConfig.fromBuilderOptions(BuilderOptions options) {
    final config = TestHtmlBuilderConfig.fromJson(options.config);
    for (final path in config.templates.keys) {
      if (!path.startsWith('./test/') && !path.startsWith('test/')) {
        throw StateError('Invalid template path: $path\n'
            'Every test html template must be located in the `test/` directory.');
      }
    }
    return config;
  }

  factory TestHtmlBuilderConfig.fromJson(Map<String, dynamic> json) {
    try {
      return _$TestHtmlBuilderConfigFromJson(json);
    } on CheckedFromJsonException catch (e) {
      final lines = <String>[
        'Could not parse the options provided for `test_html_builder`.'
      ];

      final key = e.key;
      final message = e.message;
      final innerError = e.innerError;
      if (key != null) {
        lines.add('There is a problem with "$key".');
      }
      if (message != null) {
        lines.add(message);
      } else if (innerError != null) {
        lines.add(innerError.toString());
      }

      throw StateError(lines.join('\n'));
    }
  }

  final bool browserAggregation;

  // This is meant to mirror what's happening in the dev test package if you see how the default value is determined
  // https://github.com/dart-lang/test/blob/c586cff0f415f9c3006175352b9634ba900fd7d2/pkgs/test_core/lib/src/runner/configuration/args.dart#L259-L261
  final String? randomizeOrderingSeed;

  final Map<String, List<String>> templates;

  late final Map<String, Iterable<Glob>> templateGlobs = templates.map(
      (key, globPatterns) =>
          MapEntry(key, globPatterns.map((pattern) => Glob(pattern))));

  Map<String, dynamic> toJson() => _$TestHtmlBuilderConfigToJson(this);
}
