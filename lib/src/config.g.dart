// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TestHtmlBuilderConfig _$TestHtmlBuilderConfigFromJson(
    Map<dynamic, dynamic> json) {
  return $checkedNew('TestHtmlBuilderConfig', json, () {
    $checkKeys(json, allowedKeys: const ['templates']);
    final val = TestHtmlBuilderConfig(
      templates: $checkedConvert(
          json,
          'templates',
          (v) => (v as Map<dynamic, dynamic>)?.map(
                (k, e) => MapEntry(k as String,
                    (e as List<dynamic>)?.map((e) => e as String)?.toList()),
              )),
    );
    return val;
  });
}
