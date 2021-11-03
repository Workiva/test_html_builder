// GENERATED CODE - DO NOT MODIFY BY HAND

part of lib.src.config;

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TestHtmlBuilderConfig _$TestHtmlBuilderConfigFromJson(Map json) {
  return $checkedNew('TestHtmlBuilderConfig', json, () {
    $checkKeys(json, allowedKeys: const [
      'browser_aggregation',
      'randomize_ordering_seed',
      'templates'
    ]);
    final val = TestHtmlBuilderConfig(
      browserAggregation:
          $checkedConvert(json, 'browser_aggregation', (v) => v as bool),
      randomizeOrderingSeed:
          $checkedConvert(json, 'randomize_ordering_seed', (v) => v as String),
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
    'randomizeOrderingSeed': 'randomize_ordering_seed'
  });
}

Map<String, dynamic> _$TestHtmlBuilderConfigToJson(
        TestHtmlBuilderConfig instance) =>
    <String, dynamic>{
      'browser_aggregation': instance.browserAggregation,
      'randomize_ordering_seed': instance.randomizeOrderingSeed,
      'templates': instance.templates,
    };
