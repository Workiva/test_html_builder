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
