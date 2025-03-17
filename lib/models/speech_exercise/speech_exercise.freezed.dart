// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'speech_exercise.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

SpeechExercise _$SpeechExerciseFromJson(Map<String, dynamic> json) {
  return _SpeechExercise.fromJson(json);
}

/// @nodoc
mixin _$SpeechExercise {
  String get text => throw _privateConstructorUsedError;
  int get pauseAt => throw _privateConstructorUsedError;
  int get level => throw _privateConstructorUsedError;
  int get index => throw _privateConstructorUsedError;
  String get levelId => throw _privateConstructorUsedError;
  String get videoFileName => throw _privateConstructorUsedError;

  /// Serializes this SpeechExercise to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of SpeechExercise
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SpeechExerciseCopyWith<SpeechExercise> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SpeechExerciseCopyWith<$Res> {
  factory $SpeechExerciseCopyWith(
          SpeechExercise value, $Res Function(SpeechExercise) then) =
      _$SpeechExerciseCopyWithImpl<$Res, SpeechExercise>;
  @useResult
  $Res call(
      {String text,
      int pauseAt,
      int level,
      int index,
      String levelId,
      String videoFileName});
}

/// @nodoc
class _$SpeechExerciseCopyWithImpl<$Res, $Val extends SpeechExercise>
    implements $SpeechExerciseCopyWith<$Res> {
  _$SpeechExerciseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SpeechExercise
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? text = null,
    Object? pauseAt = null,
    Object? level = null,
    Object? index = null,
    Object? levelId = null,
    Object? videoFileName = null,
  }) {
    return _then(_value.copyWith(
      text: null == text
          ? _value.text
          : text // ignore: cast_nullable_to_non_nullable
              as String,
      pauseAt: null == pauseAt
          ? _value.pauseAt
          : pauseAt // ignore: cast_nullable_to_non_nullable
              as int,
      level: null == level
          ? _value.level
          : level // ignore: cast_nullable_to_non_nullable
              as int,
      index: null == index
          ? _value.index
          : index // ignore: cast_nullable_to_non_nullable
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
abstract class _$$SpeechExerciseImplCopyWith<$Res>
    implements $SpeechExerciseCopyWith<$Res> {
  factory _$$SpeechExerciseImplCopyWith(_$SpeechExerciseImpl value,
          $Res Function(_$SpeechExerciseImpl) then) =
      __$$SpeechExerciseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String text,
      int pauseAt,
      int level,
      int index,
      String levelId,
      String videoFileName});
}

/// @nodoc
class __$$SpeechExerciseImplCopyWithImpl<$Res>
    extends _$SpeechExerciseCopyWithImpl<$Res, _$SpeechExerciseImpl>
    implements _$$SpeechExerciseImplCopyWith<$Res> {
  __$$SpeechExerciseImplCopyWithImpl(
      _$SpeechExerciseImpl _value, $Res Function(_$SpeechExerciseImpl) _then)
      : super(_value, _then);

  /// Create a copy of SpeechExercise
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? text = null,
    Object? pauseAt = null,
    Object? level = null,
    Object? index = null,
    Object? levelId = null,
    Object? videoFileName = null,
  }) {
    return _then(_$SpeechExerciseImpl(
      text: null == text
          ? _value.text
          : text // ignore: cast_nullable_to_non_nullable
              as String,
      pauseAt: null == pauseAt
          ? _value.pauseAt
          : pauseAt // ignore: cast_nullable_to_non_nullable
              as int,
      level: null == level
          ? _value.level
          : level // ignore: cast_nullable_to_non_nullable
              as int,
      index: null == index
          ? _value.index
          : index // ignore: cast_nullable_to_non_nullable
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
class _$SpeechExerciseImpl
    with DiagnosticableTreeMixin
    implements _SpeechExercise {
  const _$SpeechExerciseImpl(
      {required this.text,
      required this.pauseAt,
      required this.level,
      required this.index,
      required this.levelId,
      required this.videoFileName});

  factory _$SpeechExerciseImpl.fromJson(Map<String, dynamic> json) =>
      _$$SpeechExerciseImplFromJson(json);

  @override
  final String text;
  @override
  final int pauseAt;
  @override
  final int level;
  @override
  final int index;
  @override
  final String levelId;
  @override
  final String videoFileName;

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'SpeechExercise(text: $text, pauseAt: $pauseAt, level: $level, index: $index, levelId: $levelId, videoFileName: $videoFileName)';
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty('type', 'SpeechExercise'))
      ..add(DiagnosticsProperty('text', text))
      ..add(DiagnosticsProperty('pauseAt', pauseAt))
      ..add(DiagnosticsProperty('level', level))
      ..add(DiagnosticsProperty('index', index))
      ..add(DiagnosticsProperty('levelId', levelId))
      ..add(DiagnosticsProperty('videoFileName', videoFileName));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SpeechExerciseImpl &&
            (identical(other.text, text) || other.text == text) &&
            (identical(other.pauseAt, pauseAt) || other.pauseAt == pauseAt) &&
            (identical(other.level, level) || other.level == level) &&
            (identical(other.index, index) || other.index == index) &&
            (identical(other.levelId, levelId) || other.levelId == levelId) &&
            (identical(other.videoFileName, videoFileName) ||
                other.videoFileName == videoFileName));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, text, pauseAt, level, index, levelId, videoFileName);

  /// Create a copy of SpeechExercise
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SpeechExerciseImplCopyWith<_$SpeechExerciseImpl> get copyWith =>
      __$$SpeechExerciseImplCopyWithImpl<_$SpeechExerciseImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SpeechExerciseImplToJson(
      this,
    );
  }
}

abstract class _SpeechExercise implements SpeechExercise {
  const factory _SpeechExercise(
      {required final String text,
      required final int pauseAt,
      required final int level,
      required final int index,
      required final String levelId,
      required final String videoFileName}) = _$SpeechExerciseImpl;

  factory _SpeechExercise.fromJson(Map<String, dynamic> json) =
      _$SpeechExerciseImpl.fromJson;

  @override
  String get text;
  @override
  int get pauseAt;
  @override
  int get level;
  @override
  int get index;
  @override
  String get levelId;
  @override
  String get videoFileName;

  /// Create a copy of SpeechExercise
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SpeechExerciseImplCopyWith<_$SpeechExerciseImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

SpeechExerciseDTO _$SpeechExerciseDTOFromJson(Map<String, dynamic> json) {
  return _SpeechExerciseDTO.fromJson(json);
}

/// @nodoc
mixin _$SpeechExerciseDTO {
  String get videoFileName => throw _privateConstructorUsedError;
  String get text => throw _privateConstructorUsedError;
  int get pauseAt => throw _privateConstructorUsedError;
  int get zip => throw _privateConstructorUsedError;

  /// Serializes this SpeechExerciseDTO to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of SpeechExerciseDTO
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SpeechExerciseDTOCopyWith<SpeechExerciseDTO> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SpeechExerciseDTOCopyWith<$Res> {
  factory $SpeechExerciseDTOCopyWith(
          SpeechExerciseDTO value, $Res Function(SpeechExerciseDTO) then) =
      _$SpeechExerciseDTOCopyWithImpl<$Res, SpeechExerciseDTO>;
  @useResult
  $Res call({String videoFileName, String text, int pauseAt, int zip});
}

/// @nodoc
class _$SpeechExerciseDTOCopyWithImpl<$Res, $Val extends SpeechExerciseDTO>
    implements $SpeechExerciseDTOCopyWith<$Res> {
  _$SpeechExerciseDTOCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SpeechExerciseDTO
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? videoFileName = null,
    Object? text = null,
    Object? pauseAt = null,
    Object? zip = null,
  }) {
    return _then(_value.copyWith(
      videoFileName: null == videoFileName
          ? _value.videoFileName
          : videoFileName // ignore: cast_nullable_to_non_nullable
              as String,
      text: null == text
          ? _value.text
          : text // ignore: cast_nullable_to_non_nullable
              as String,
      pauseAt: null == pauseAt
          ? _value.pauseAt
          : pauseAt // ignore: cast_nullable_to_non_nullable
              as int,
      zip: null == zip
          ? _value.zip
          : zip // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$SpeechExerciseDTOImplCopyWith<$Res>
    implements $SpeechExerciseDTOCopyWith<$Res> {
  factory _$$SpeechExerciseDTOImplCopyWith(_$SpeechExerciseDTOImpl value,
          $Res Function(_$SpeechExerciseDTOImpl) then) =
      __$$SpeechExerciseDTOImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String videoFileName, String text, int pauseAt, int zip});
}

/// @nodoc
class __$$SpeechExerciseDTOImplCopyWithImpl<$Res>
    extends _$SpeechExerciseDTOCopyWithImpl<$Res, _$SpeechExerciseDTOImpl>
    implements _$$SpeechExerciseDTOImplCopyWith<$Res> {
  __$$SpeechExerciseDTOImplCopyWithImpl(_$SpeechExerciseDTOImpl _value,
      $Res Function(_$SpeechExerciseDTOImpl) _then)
      : super(_value, _then);

  /// Create a copy of SpeechExerciseDTO
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? videoFileName = null,
    Object? text = null,
    Object? pauseAt = null,
    Object? zip = null,
  }) {
    return _then(_$SpeechExerciseDTOImpl(
      videoFileName: null == videoFileName
          ? _value.videoFileName
          : videoFileName // ignore: cast_nullable_to_non_nullable
              as String,
      text: null == text
          ? _value.text
          : text // ignore: cast_nullable_to_non_nullable
              as String,
      pauseAt: null == pauseAt
          ? _value.pauseAt
          : pauseAt // ignore: cast_nullable_to_non_nullable
              as int,
      zip: null == zip
          ? _value.zip
          : zip // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$SpeechExerciseDTOImpl
    with DiagnosticableTreeMixin
    implements _SpeechExerciseDTO {
  const _$SpeechExerciseDTOImpl(
      {required this.videoFileName,
      required this.text,
      required this.pauseAt,
      required this.zip});

  factory _$SpeechExerciseDTOImpl.fromJson(Map<String, dynamic> json) =>
      _$$SpeechExerciseDTOImplFromJson(json);

  @override
  final String videoFileName;
  @override
  final String text;
  @override
  final int pauseAt;
  @override
  final int zip;

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'SpeechExerciseDTO(videoFileName: $videoFileName, text: $text, pauseAt: $pauseAt, zip: $zip)';
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty('type', 'SpeechExerciseDTO'))
      ..add(DiagnosticsProperty('videoFileName', videoFileName))
      ..add(DiagnosticsProperty('text', text))
      ..add(DiagnosticsProperty('pauseAt', pauseAt))
      ..add(DiagnosticsProperty('zip', zip));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SpeechExerciseDTOImpl &&
            (identical(other.videoFileName, videoFileName) ||
                other.videoFileName == videoFileName) &&
            (identical(other.text, text) || other.text == text) &&
            (identical(other.pauseAt, pauseAt) || other.pauseAt == pauseAt) &&
            (identical(other.zip, zip) || other.zip == zip));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, videoFileName, text, pauseAt, zip);

  /// Create a copy of SpeechExerciseDTO
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SpeechExerciseDTOImplCopyWith<_$SpeechExerciseDTOImpl> get copyWith =>
      __$$SpeechExerciseDTOImplCopyWithImpl<_$SpeechExerciseDTOImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SpeechExerciseDTOImplToJson(
      this,
    );
  }
}

abstract class _SpeechExerciseDTO implements SpeechExerciseDTO {
  const factory _SpeechExerciseDTO(
      {required final String videoFileName,
      required final String text,
      required final int pauseAt,
      required final int zip}) = _$SpeechExerciseDTOImpl;

  factory _SpeechExerciseDTO.fromJson(Map<String, dynamic> json) =
      _$SpeechExerciseDTOImpl.fromJson;

  @override
  String get videoFileName;
  @override
  String get text;
  @override
  int get pauseAt;
  @override
  int get zip;

  /// Create a copy of SpeechExerciseDTO
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SpeechExerciseDTOImplCopyWith<_$SpeechExerciseDTOImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
