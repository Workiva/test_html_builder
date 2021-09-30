// GENERATED CODE - DO NOT MODIFY BY HAND

part of lib.src.config;

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TestHtmlBuilderConfig _$TestHtmlBuilderConfigFromJson(Map json) {
  return $checkedNew('TestHtmlBuilderConfig', json, () {
    $checkKeys(json, allowedKeys: const [
      'browser_aggregation',
      'randomize_aggregation',
      'templates'
    ]);
    final val = TestHtmlBuilderConfig(
      browserAggregation:
          $checkedConvert(json, 'browser_aggregation', (v) => v as bool),
      randomizeAggregation:
          $checkedConvert(json, 'randomize_aggregation', (v) => v as bool),
      templates: $checkedConvert(
          json,
          'templates',
          (v) => (v as Map)?.map(
                (k, e) => MapEntry(k as String,
                    (e as List)?.map((e) => e as String)?.toList()),
              )),
    );
    return val;
  }, fieldKeyMap: const {
    'browserAggregation': 'browser_aggregation',
    'randomizeAggregation': 'randomize_aggregation'
  });
}

Map<String, dynamic> _$TestHtmlBuilderConfigToJson(
        TestHtmlBuilderConfig instance) =>
    <String, dynamic>{
      'browser_aggregation': instance.browserAggregation,
      'randomize_aggregation': instance.randomizeAggregation,
      'templates': instance.templates,
    };
