// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'video.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$VideoImpl _$$VideoImplFromJson(Map<String, dynamic> json) => _$VideoImpl(
      level: (json['level'] as num).toInt(),
      index: (json['index'] as num).toInt(),
      levelId: json['levelId'] as String,
      videoFileName: json['videoFileName'] as String,
    );

Map<String, dynamic> _$$VideoImplToJson(_$VideoImpl instance) =>
    <String, dynamic>{
      'level': instance.level,
      'index': instance.index,
      'levelId': instance.levelId,
      'videoFileName': instance.videoFileName,
    };

_$VideoDTOImpl _$$VideoDTOImplFromJson(Map<String, dynamic> json) =>
    _$VideoDTOImpl(
      videoFileName: json['videoFileName'] as String,
      zip: (json['zip'] as num).toInt(),
    );

Map<String, dynamic> _$$VideoDTOImplToJson(_$VideoDTOImpl instance) =>
    <String, dynamic>{
      'videoFileName': instance.videoFileName,
      'zip': instance.zip,
    };
