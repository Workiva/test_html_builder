import 'package:glob/glob.dart';
import 'package:json_annotation/json_annotation.dart';

part 'config.g.dart';

@JsonSerializable(anyMap: true, checked: true, disallowUnrecognizedKeys: true)
class TestHtmlBuilderConfig {
  final Map<String, List<String>> templates;

  Map<String, Iterable<Glob>> get templateGlobs {
    _templateGlobs ??= templates.map((key, globPatterns) =>
        MapEntry(key, globPatterns.map((pattern) => Glob(pattern))));
    return _templateGlobs;
  }

  Map<String, Iterable<Glob>> _templateGlobs;

  TestHtmlBuilderConfig({templates}) : templates = templates ?? {};

  factory TestHtmlBuilderConfig.fromJson(Map<String, dynamic> json) {
    try {
      // The build package handles parsing `build.yaml`, but they can only
      // enforce strong typing of the schemas of which they are aware. For the
      // builder options specific to this test_html_builder, we have to attempt
      // to cast to the expected types in order for the json_serializable
      // type checking logic to work as expected.
      json = Map<String, dynamic>.from(json);
      if (json['templates'] != null) {
        json['templates'] = Map.from(json['templates']);
        for (final key in json['templates'].keys) {
          json['templates'][key] =
              List.castFrom<dynamic, String>(json['templates'][key]);
        }
        json['templates'] = Map<String, List<String>>.from(json['templates']);
      }
    } catch (e) {
      print('Failed to cast `templates`: $e');
      rethrow;
    }
    return _$TestHtmlBuilderConfigFromJson(json);
  }
}
