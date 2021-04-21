// GENERATED CODE - DO NOT MODIFY BY HAND

part of lib.src.config;

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TestHtmlBuilderConfig _$TestHtmlBuilderConfigFromJson(Map json) {
  return $checkedNew('TestHtmlBuilderConfig', json, () {
    $checkKeys(json, allowedKeys: const ['dart2js_aggregation', 'templates']);
    final val = TestHtmlBuilderConfig(
      dart2jsAggregation:
          $checkedConvert(json, 'dart2js_aggregation', (v) => v as bool),
      templates: $checkedConvert(
          json,
          'templates',
          (v) => (v as Map)?.map(
                (k, e) => MapEntry(k as String,
                    (e as List)?.map((e) => e as String)?.toList()),
              )),
    );
    return val;
  }, fieldKeyMap: const {'dart2jsAggregation': 'dart2js_aggregation'});
}

Map<String, dynamic> _$TestHtmlBuilderConfigToJson(
        TestHtmlBuilderConfig instance) =>
    <String, dynamic>{
      'dart2js_aggregation': instance.dart2jsAggregation,
      'templates': instance.templates,
    };
