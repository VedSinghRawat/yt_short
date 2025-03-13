// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'video.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Video _$VideoFromJson(Map<String, dynamic> json) {
  return _Video.fromJson(json);
}

/// @nodoc
mixin _$Video {
  int get level => throw _privateConstructorUsedError;
  int get subLevel => throw _privateConstructorUsedError;
  String get levelId => throw _privateConstructorUsedError;
  String get videoFileName => throw _privateConstructorUsedError;

  /// Serializes this Video to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Video
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $VideoCopyWith<Video> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $VideoCopyWith<$Res> {
  factory $VideoCopyWith(Video value, $Res Function(Video) then) =
      _$VideoCopyWithImpl<$Res, Video>;
  @useResult
  $Res call({int level, int subLevel, String levelId, String videoFileName});
}

/// @nodoc
class _$VideoCopyWithImpl<$Res, $Val extends Video>
    implements $VideoCopyWith<$Res> {
  _$VideoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Video
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? level = null,
    Object? subLevel = null,
    Object? levelId = null,
    Object? videoFileName = null,
  }) {
    return _then(_value.copyWith(
      level: null == level
          ? _value.level
          : level // ignore: cast_nullable_to_non_nullable
              as int,
      subLevel: null == subLevel
          ? _value.subLevel
          : subLevel // ignore: cast_nullable_to_non_nullable
              as int,
      levelId: null == levelId
          ? _value.levelId
          : levelId // ignore: cast_nullable_to_non_nullable
              as String,
      videoFileName: null == videoFileName
          ? _value.videoFileName
          : videoFileName // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$VideoImplCopyWith<$Res> implements $VideoCopyWith<$Res> {
  factory _$$VideoImplCopyWith(
          _$VideoImpl value, $Res Function(_$VideoImpl) then) =
      __$$VideoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({int level, int subLevel, String levelId, String videoFileName});
}

/// @nodoc
class __$$VideoImplCopyWithImpl<$Res>
    extends _$VideoCopyWithImpl<$Res, _$VideoImpl>
    implements _$$VideoImplCopyWith<$Res> {
  __$$VideoImplCopyWithImpl(
      _$VideoImpl _value, $Res Function(_$VideoImpl) _then)
      : super(_value, _then);

  /// Create a copy of Video
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? level = null,
    Object? subLevel = null,
    Object? levelId = null,
    Object? videoFileName = null,
  }) {
    return _then(_$VideoImpl(
      level: null == level
          ? _value.level
          : level // ignore: cast_nullable_to_non_nullable
              as int,
      subLevel: null == subLevel
          ? _value.subLevel
          : subLevel // ignore: cast_nullable_to_non_nullable
              as int,
      levelId: null == levelId
          ? _value.levelId
          : levelId // ignore: cast_nullable_to_non_nullable
              as String,
      videoFileName: null == videoFileName
          ? _value.videoFileName
          : videoFileName // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$VideoImpl with DiagnosticableTreeMixin implements _Video {
  const _$VideoImpl(
      {required this.level,
      required this.subLevel,
      required this.levelId,
      required this.videoFileName});

  factory _$VideoImpl.fromJson(Map<String, dynamic> json) =>
      _$$VideoImplFromJson(json);

  @override
  final int level;
  @override
  final int subLevel;
  @override
  final String levelId;
  @override
  final String videoFileName;

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'Video(level: $level, subLevel: $subLevel, levelId: $levelId, videoFileName: $videoFileName)';
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty('type', 'Video'))
      ..add(DiagnosticsProperty('level', level))
      ..add(DiagnosticsProperty('subLevel', subLevel))
      ..add(DiagnosticsProperty('levelId', levelId))
      ..add(DiagnosticsProperty('videoFileName', videoFileName));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$VideoImpl &&
            (identical(other.level, level) || other.level == level) &&
            (identical(other.subLevel, subLevel) ||
                other.subLevel == subLevel) &&
            (identical(other.levelId, levelId) || other.levelId == levelId) &&
            (identical(other.videoFileName, videoFileName) ||
                other.videoFileName == videoFileName));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, level, subLevel, levelId, videoFileName);

  /// Create a copy of Video
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$VideoImplCopyWith<_$VideoImpl> get copyWith =>
      __$$VideoImplCopyWithImpl<_$VideoImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$VideoImplToJson(
      this,
    );
  }
}

abstract class _Video implements Video {
  const factory _Video(
      {required final int level,
      required final int subLevel,
      required final String levelId,
      required final String videoFileName}) = _$VideoImpl;

  factory _Video.fromJson(Map<String, dynamic> json) = _$VideoImpl.fromJson;

  @override
  int get level;
  @override
  int get subLevel;
  @override
  String get levelId;
  @override
  String get videoFileName;

  /// Create a copy of Video
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$VideoImplCopyWith<_$VideoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

VideoDTO _$VideoDTOFromJson(Map<String, dynamic> json) {
  return _VideoDTO.fromJson(json);
}

/// @nodoc
mixin _$VideoDTO {
  String get videoFileName => throw _privateConstructorUsedError;
  int get zip => throw _privateConstructorUsedError;

  /// Serializes this VideoDTO to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of VideoDTO
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $VideoDTOCopyWith<VideoDTO> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $VideoDTOCopyWith<$Res> {
  factory $VideoDTOCopyWith(VideoDTO value, $Res Function(VideoDTO) then) =
      _$VideoDTOCopyWithImpl<$Res, VideoDTO>;
  @useResult
  $Res call({String videoFileName, int zip});
}

/// @nodoc
class _$VideoDTOCopyWithImpl<$Res, $Val extends VideoDTO>
    implements $VideoDTOCopyWith<$Res> {
  _$VideoDTOCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of VideoDTO
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? videoFileName = null,
    Object? zip = null,
  }) {
    return _then(_value.copyWith(
      videoFileName: null == videoFileName
          ? _value.videoFileName
          : videoFileName // ignore: cast_nullable_to_non_nullable
              as String,
      zip: null == zip
          ? _value.zip
          : zip // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$VideoDTOImplCopyWith<$Res>
    implements $VideoDTOCopyWith<$Res> {
  factory _$$VideoDTOImplCopyWith(
          _$VideoDTOImpl value, $Res Function(_$VideoDTOImpl) then) =
      __$$VideoDTOImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String videoFileName, int zip});
}

/// @nodoc
class __$$VideoDTOImplCopyWithImpl<$Res>
    extends _$VideoDTOCopyWithImpl<$Res, _$VideoDTOImpl>
    implements _$$VideoDTOImplCopyWith<$Res> {
  __$$VideoDTOImplCopyWithImpl(
      _$VideoDTOImpl _value, $Res Function(_$VideoDTOImpl) _then)
      : super(_value, _then);

  /// Create a copy of VideoDTO
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? videoFileName = null,
    Object? zip = null,
  }) {
    return _then(_$VideoDTOImpl(
      videoFileName: null == videoFileName
          ? _value.videoFileName
          : videoFileName // ignore: cast_nullable_to_non_nullable
              as String,
      zip: null == zip
          ? _value.zip
          : zip // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$VideoDTOImpl with DiagnosticableTreeMixin implements _VideoDTO {
  const _$VideoDTOImpl({required this.videoFileName, required this.zip});

  factory _$VideoDTOImpl.fromJson(Map<String, dynamic> json) =>
      _$$VideoDTOImplFromJson(json);

  @override
  final String videoFileName;
  @override
  final int zip;

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'VideoDTO(videoFileName: $videoFileName, zip: $zip)';
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty('type', 'VideoDTO'))
      ..add(DiagnosticsProperty('videoFileName', videoFileName))
      ..add(DiagnosticsProperty('zip', zip));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$VideoDTOImpl &&
            (identical(other.videoFileName, videoFileName) ||
                other.videoFileName == videoFileName) &&
            (identical(other.zip, zip) || other.zip == zip));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, videoFileName, zip);

  /// Create a copy of VideoDTO
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$VideoDTOImplCopyWith<_$VideoDTOImpl> get copyWith =>
      __$$VideoDTOImplCopyWithImpl<_$VideoDTOImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$VideoDTOImplToJson(
      this,
    );
  }
}

abstract class _VideoDTO implements VideoDTO {
  const factory _VideoDTO(
      {required final String videoFileName,
      required final int zip}) = _$VideoDTOImpl;

  factory _VideoDTO.fromJson(Map<String, dynamic> json) =
      _$VideoDTOImpl.fromJson;

  @override
  String get videoFileName;
  @override
  int get zip;

  /// Create a copy of VideoDTO
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$VideoDTOImplCopyWith<_$VideoDTOImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
