// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TestHtmlBuilderConfig _$TestHtmlBuilderConfigFromJson(Map json) {
  return $checkedNew('TestHtmlBuilderConfig', json, () {
    $checkKeys(json, allowedKeys: const ['templates']);
    final val = TestHtmlBuilderConfig(
        templates: $checkedConvert(json, 'templates', (v) => v));
    return val;
  });
}

Map<String, dynamic> _$TestHtmlBuilderConfigToJson(
        TestHtmlBuilderConfig instance) =>
    <String, dynamic>{'templates': instance.templates};
