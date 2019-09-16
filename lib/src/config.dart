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

import 'package:glob/glob.dart';
import 'package:json_annotation/json_annotation.dart';

part 'config.g.dart';

@JsonSerializable(
    anyMap: true,
    checked: true,
    createToJson: false,
    disallowUnrecognizedKeys: true)
class TestHtmlBuilderConfig {
  TestHtmlBuilderConfig({Map<String, List<String>> templates})
      : templates = templates ?? {};

  factory TestHtmlBuilderConfig.fromJson(Map<String, dynamic> json) =>
      _$TestHtmlBuilderConfigFromJson(json);

  final Map<String, List<String>> templates;

  Map<String, Iterable<Glob>> get templateGlobs {
    _templateGlobs ??= templates.map((key, globPatterns) =>
        MapEntry(key, globPatterns.map((pattern) => Glob(pattern))));
    return _templateGlobs;
  }

  Map<String, Iterable<Glob>> _templateGlobs;
}
