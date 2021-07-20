// GENERATED CODE - DO NOT MODIFY BY HAND

part of lib.src.config;

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TestHtmlBuilderConfig _$TestHtmlBuilderConfigFromJson(Map json) {
  return $checkedNew('TestHtmlBuilderConfig', json, () {
    $checkKeys(json, allowedKeys: const ['browser_aggregation', 'templates']);
    final val = TestHtmlBuilderConfig(
      browserAggregation:
          $checkedConvert(json, 'browser_aggregation', (v) => v as bool?),
      templates: $checkedConvert(
          json,
          'templates',
          (v) => (v as Map?)?.map(
                (k, e) => MapEntry(k as String,
                    (e as List<dynamic>).map((e) => e as String).toList()),
              )),
    );
    return val;
  }, fieldKeyMap: const {'browserAggregation': 'browser_aggregation'});
}

Map<String, dynamic> _$TestHtmlBuilderConfigToJson(
        TestHtmlBuilderConfig instance) =>
    <String, dynamic>{
      'browser_aggregation': instance.browserAggregation,
      'templates': instance.templates,
    };
