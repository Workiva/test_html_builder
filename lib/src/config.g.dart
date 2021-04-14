// GENERATED CODE - DO NOT MODIFY BY HAND

part of lib.src.config;

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TestHtmlBuilderConfig _$TestHtmlBuilderConfigFromJson(Map json) {
  return $checkedNew('TestHtmlBuilderConfig', json, () {
    $checkKeys(json, allowedKeys: const ['aggregateForDart2js', 'templates']);
    final val = TestHtmlBuilderConfig(
      aggregateForDart2js:
          $checkedConvert(json, 'aggregateForDart2js', (v) => v as bool),
      templates: $checkedConvert(
          json,
          'templates',
          (v) => (v as Map)?.map(
                (k, e) => MapEntry(k as String,
                    (e as List)?.map((e) => e as String)?.toList()),
              )),
    );
    return val;
  });
}

Map<String, dynamic> _$TestHtmlBuilderConfigToJson(
        TestHtmlBuilderConfig instance) =>
    <String, dynamic>{
      'aggregateForDart2js': instance.aggregateForDart2js,
      'templates': instance.templates,
    };
