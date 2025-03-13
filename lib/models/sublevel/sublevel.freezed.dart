// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'sublevel.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$SubLevel {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(SpeechExercise speechExercise) speechExercise,
    required TResult Function(Video video) video,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(SpeechExercise speechExercise)? speechExercise,
    TResult? Function(Video video)? video,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(SpeechExercise speechExercise)? speechExercise,
    TResult Function(Video video)? video,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_SpeechExercise value) speechExercise,
    required TResult Function(_Video value) video,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_SpeechExercise value)? speechExercise,
    TResult? Function(_Video value)? video,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_SpeechExercise value)? speechExercise,
    TResult Function(_Video value)? video,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SubLevelCopyWith<$Res> {
  factory $SubLevelCopyWith(SubLevel value, $Res Function(SubLevel) then) =
      _$SubLevelCopyWithImpl<$Res, SubLevel>;
}

/// @nodoc
class _$SubLevelCopyWithImpl<$Res, $Val extends SubLevel>
    implements $SubLevelCopyWith<$Res> {
  _$SubLevelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SubLevel
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc
abstract class _$$SpeechExerciseImplCopyWith<$Res> {
  factory _$$SpeechExerciseImplCopyWith(_$SpeechExerciseImpl value,
          $Res Function(_$SpeechExerciseImpl) then) =
      __$$SpeechExerciseImplCopyWithImpl<$Res>;
  @useResult
  $Res call({SpeechExercise speechExercise});

  $SpeechExerciseCopyWith<$Res> get speechExercise;
}

/// @nodoc
class __$$SpeechExerciseImplCopyWithImpl<$Res>
    extends _$SubLevelCopyWithImpl<$Res, _$SpeechExerciseImpl>
    implements _$$SpeechExerciseImplCopyWith<$Res> {
  __$$SpeechExerciseImplCopyWithImpl(
      _$SpeechExerciseImpl _value, $Res Function(_$SpeechExerciseImpl) _then)
      : super(_value, _then);

  /// Create a copy of SubLevel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? speechExercise = null,
  }) {
    return _then(_$SpeechExerciseImpl(
      null == speechExercise
          ? _value.speechExercise
          : speechExercise // ignore: cast_nullable_to_non_nullable
              as SpeechExercise,
    ));
  }

  /// Create a copy of SubLevel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $SpeechExerciseCopyWith<$Res> get speechExercise {
    return $SpeechExerciseCopyWith<$Res>(_value.speechExercise, (value) {
      return _then(_value.copyWith(speechExercise: value));
    });
  }
}

/// @nodoc

class _$SpeechExerciseImpl extends _SpeechExercise {
  const _$SpeechExerciseImpl(this.speechExercise) : super._();

  @override
  final SpeechExercise speechExercise;

  @override
  String toString() {
    return 'SubLevel.speechExercise(speechExercise: $speechExercise)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SpeechExerciseImpl &&
            (identical(other.speechExercise, speechExercise) ||
                other.speechExercise == speechExercise));
  }

  @override
  int get hashCode => Object.hash(runtimeType, speechExercise);

  /// Create a copy of SubLevel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SpeechExerciseImplCopyWith<_$SpeechExerciseImpl> get copyWith =>
      __$$SpeechExerciseImplCopyWithImpl<_$SpeechExerciseImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(SpeechExercise speechExercise) speechExercise,
    required TResult Function(Video video) video,
  }) {
    return speechExercise(this.speechExercise);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(SpeechExercise speechExercise)? speechExercise,
    TResult? Function(Video video)? video,
  }) {
    return speechExercise?.call(this.speechExercise);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(SpeechExercise speechExercise)? speechExercise,
    TResult Function(Video video)? video,
    required TResult orElse(),
  }) {
    if (speechExercise != null) {
      return speechExercise(this.speechExercise);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_SpeechExercise value) speechExercise,
    required TResult Function(_Video value) video,
  }) {
    return speechExercise(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_SpeechExercise value)? speechExercise,
    TResult? Function(_Video value)? video,
  }) {
    return speechExercise?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_SpeechExercise value)? speechExercise,
    TResult Function(_Video value)? video,
    required TResult orElse(),
  }) {
    if (speechExercise != null) {
      return speechExercise(this);
    }
    return orElse();
  }
}

abstract class _SpeechExercise extends SubLevel {
  const factory _SpeechExercise(final SpeechExercise speechExercise) =
      _$SpeechExerciseImpl;
  const _SpeechExercise._() : super._();

  SpeechExercise get speechExercise;

  /// Create a copy of SubLevel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SpeechExerciseImplCopyWith<_$SpeechExerciseImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$VideoImplCopyWith<$Res> {
  factory _$$VideoImplCopyWith(
          _$VideoImpl value, $Res Function(_$VideoImpl) then) =
      __$$VideoImplCopyWithImpl<$Res>;
  @useResult
  $Res call({Video video});

  $VideoCopyWith<$Res> get video;
}

/// @nodoc
class __$$VideoImplCopyWithImpl<$Res>
    extends _$SubLevelCopyWithImpl<$Res, _$VideoImpl>
    implements _$$VideoImplCopyWith<$Res> {
  __$$VideoImplCopyWithImpl(
      _$VideoImpl _value, $Res Function(_$VideoImpl) _then)
      : super(_value, _then);

  /// Create a copy of SubLevel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? video = null,
  }) {
    return _then(_$VideoImpl(
      null == video
          ? _value.video
          : video // ignore: cast_nullable_to_non_nullable
              as Video,
    ));
  }

  /// Create a copy of SubLevel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $VideoCopyWith<$Res> get video {
    return $VideoCopyWith<$Res>(_value.video, (value) {
      return _then(_value.copyWith(video: value));
    });
  }
}

/// @nodoc

class _$VideoImpl extends _Video {
  const _$VideoImpl(this.video) : super._();

  @override
  final Video video;

  @override
  String toString() {
    return 'SubLevel.video(video: $video)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$VideoImpl &&
            (identical(other.video, video) || other.video == video));
  }

  @override
  int get hashCode => Object.hash(runtimeType, video);

  /// Create a copy of SubLevel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$VideoImplCopyWith<_$VideoImpl> get copyWith =>
      __$$VideoImplCopyWithImpl<_$VideoImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(SpeechExercise speechExercise) speechExercise,
    required TResult Function(Video video) video,
  }) {
    return video(this.video);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(SpeechExercise speechExercise)? speechExercise,
    TResult? Function(Video video)? video,
  }) {
    return video?.call(this.video);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(SpeechExercise speechExercise)? speechExercise,
    TResult Function(Video video)? video,
    required TResult orElse(),
  }) {
    if (video != null) {
      return video(this.video);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_SpeechExercise value) speechExercise,
    required TResult Function(_Video value) video,
  }) {
    return video(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_SpeechExercise value)? speechExercise,
    TResult? Function(_Video value)? video,
  }) {
    return video?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_SpeechExercise value)? speechExercise,
    TResult Function(_Video value)? video,
    required TResult orElse(),
  }) {
    if (video != null) {
      return video(this);
    }
    return orElse();
  }
}

abstract class _Video extends SubLevel {
  const factory _Video(final Video video) = _$VideoImpl;
  const _Video._() : super._();

  Video get video;

  /// Create a copy of SubLevel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$VideoImplCopyWith<_$VideoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$SubLevelDTO {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(SpeechExerciseDTO speechExercise) speechExercise,
    required TResult Function(VideoDTO video) video,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(SpeechExerciseDTO speechExercise)? speechExercise,
    TResult? Function(VideoDTO video)? video,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(SpeechExerciseDTO speechExercise)? speechExercise,
    TResult Function(VideoDTO video)? video,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_SpeechExerciseDTO value) speechExercise,
    required TResult Function(_VideoDTO value) video,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_SpeechExerciseDTO value)? speechExercise,
    TResult? Function(_VideoDTO value)? video,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_SpeechExerciseDTO value)? speechExercise,
    TResult Function(_VideoDTO value)? video,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SubLevelDTOCopyWith<$Res> {
  factory $SubLevelDTOCopyWith(
          SubLevelDTO value, $Res Function(SubLevelDTO) then) =
      _$SubLevelDTOCopyWithImpl<$Res, SubLevelDTO>;
}

/// @nodoc
class _$SubLevelDTOCopyWithImpl<$Res, $Val extends SubLevelDTO>
    implements $SubLevelDTOCopyWith<$Res> {
  _$SubLevelDTOCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SubLevelDTO
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc
abstract class _$$SpeechExerciseDTOImplCopyWith<$Res> {
  factory _$$SpeechExerciseDTOImplCopyWith(_$SpeechExerciseDTOImpl value,
          $Res Function(_$SpeechExerciseDTOImpl) then) =
      __$$SpeechExerciseDTOImplCopyWithImpl<$Res>;
  @useResult
  $Res call({SpeechExerciseDTO speechExercise});

  $SpeechExerciseDTOCopyWith<$Res> get speechExercise;
}

/// @nodoc
class __$$SpeechExerciseDTOImplCopyWithImpl<$Res>
    extends _$SubLevelDTOCopyWithImpl<$Res, _$SpeechExerciseDTOImpl>
    implements _$$SpeechExerciseDTOImplCopyWith<$Res> {
  __$$SpeechExerciseDTOImplCopyWithImpl(_$SpeechExerciseDTOImpl _value,
      $Res Function(_$SpeechExerciseDTOImpl) _then)
      : super(_value, _then);

  /// Create a copy of SubLevelDTO
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? speechExercise = null,
  }) {
    return _then(_$SpeechExerciseDTOImpl(
      null == speechExercise
          ? _value.speechExercise
          : speechExercise // ignore: cast_nullable_to_non_nullable
              as SpeechExerciseDTO,
    ));
  }

  /// Create a copy of SubLevelDTO
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $SpeechExerciseDTOCopyWith<$Res> get speechExercise {
    return $SpeechExerciseDTOCopyWith<$Res>(_value.speechExercise, (value) {
      return _then(_value.copyWith(speechExercise: value));
    });
  }
}

/// @nodoc

class _$SpeechExerciseDTOImpl extends _SpeechExerciseDTO {
  const _$SpeechExerciseDTOImpl(this.speechExercise) : super._();

  @override
  final SpeechExerciseDTO speechExercise;

  @override
  String toString() {
    return 'SubLevelDTO.speechExercise(speechExercise: $speechExercise)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SpeechExerciseDTOImpl &&
            (identical(other.speechExercise, speechExercise) ||
                other.speechExercise == speechExercise));
  }

  @override
  int get hashCode => Object.hash(runtimeType, speechExercise);

  /// Create a copy of SubLevelDTO
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SpeechExerciseDTOImplCopyWith<_$SpeechExerciseDTOImpl> get copyWith =>
      __$$SpeechExerciseDTOImplCopyWithImpl<_$SpeechExerciseDTOImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(SpeechExerciseDTO speechExercise) speechExercise,
    required TResult Function(VideoDTO video) video,
  }) {
    return speechExercise(this.speechExercise);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(SpeechExerciseDTO speechExercise)? speechExercise,
    TResult? Function(VideoDTO video)? video,
  }) {
    return speechExercise?.call(this.speechExercise);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(SpeechExerciseDTO speechExercise)? speechExercise,
    TResult Function(VideoDTO video)? video,
    required TResult orElse(),
  }) {
    if (speechExercise != null) {
      return speechExercise(this.speechExercise);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_SpeechExerciseDTO value) speechExercise,
    required TResult Function(_VideoDTO value) video,
  }) {
    return speechExercise(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_SpeechExerciseDTO value)? speechExercise,
    TResult? Function(_VideoDTO value)? video,
  }) {
    return speechExercise?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_SpeechExerciseDTO value)? speechExercise,
    TResult Function(_VideoDTO value)? video,
    required TResult orElse(),
  }) {
    if (speechExercise != null) {
      return speechExercise(this);
    }
    return orElse();
  }
}

abstract class _SpeechExerciseDTO extends SubLevelDTO {
  const factory _SpeechExerciseDTO(final SpeechExerciseDTO speechExercise) =
      _$SpeechExerciseDTOImpl;
  const _SpeechExerciseDTO._() : super._();

  SpeechExerciseDTO get speechExercise;

  /// Create a copy of SubLevelDTO
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SpeechExerciseDTOImplCopyWith<_$SpeechExerciseDTOImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$VideoDTOImplCopyWith<$Res> {
  factory _$$VideoDTOImplCopyWith(
          _$VideoDTOImpl value, $Res Function(_$VideoDTOImpl) then) =
      __$$VideoDTOImplCopyWithImpl<$Res>;
  @useResult
  $Res call({VideoDTO video});

  $VideoDTOCopyWith<$Res> get video;
}

/// @nodoc
class __$$VideoDTOImplCopyWithImpl<$Res>
    extends _$SubLevelDTOCopyWithImpl<$Res, _$VideoDTOImpl>
    implements _$$VideoDTOImplCopyWith<$Res> {
  __$$VideoDTOImplCopyWithImpl(
      _$VideoDTOImpl _value, $Res Function(_$VideoDTOImpl) _then)
      : super(_value, _then);

  /// Create a copy of SubLevelDTO
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? video = null,
  }) {
    return _then(_$VideoDTOImpl(
      null == video
          ? _value.video
          : video // ignore: cast_nullable_to_non_nullable
              as VideoDTO,
    ));
  }

  /// Create a copy of SubLevelDTO
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $VideoDTOCopyWith<$Res> get video {
    return $VideoDTOCopyWith<$Res>(_value.video, (value) {
      return _then(_value.copyWith(video: value));
    });
  }
}

/// @nodoc

class _$VideoDTOImpl extends _VideoDTO {
  const _$VideoDTOImpl(this.video) : super._();

  @override
  final VideoDTO video;

  @override
  String toString() {
    return 'SubLevelDTO.video(video: $video)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$VideoDTOImpl &&
            (identical(other.video, video) || other.video == video));
  }

  @override
  int get hashCode => Object.hash(runtimeType, video);

  /// Create a copy of SubLevelDTO
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$VideoDTOImplCopyWith<_$VideoDTOImpl> get copyWith =>
      __$$VideoDTOImplCopyWithImpl<_$VideoDTOImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(SpeechExerciseDTO speechExercise) speechExercise,
    required TResult Function(VideoDTO video) video,
  }) {
    return video(this.video);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(SpeechExerciseDTO speechExercise)? speechExercise,
    TResult? Function(VideoDTO video)? video,
  }) {
    return video?.call(this.video);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(SpeechExerciseDTO speechExercise)? speechExercise,
    TResult Function(VideoDTO video)? video,
    required TResult orElse(),
  }) {
    if (video != null) {
      return video(this.video);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_SpeechExerciseDTO value) speechExercise,
    required TResult Function(_VideoDTO value) video,
  }) {
    return video(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_SpeechExerciseDTO value)? speechExercise,
    TResult? Function(_VideoDTO value)? video,
  }) {
    return video?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_SpeechExerciseDTO value)? speechExercise,
    TResult Function(_VideoDTO value)? video,
    required TResult orElse(),
  }) {
    if (video != null) {
      return video(this);
    }
    return orElse();
  }
}

abstract class _VideoDTO extends SubLevelDTO {
  const factory _VideoDTO(final VideoDTO video) = _$VideoDTOImpl;
  const _VideoDTO._() : super._();

  VideoDTO get video;

  /// Create a copy of SubLevelDTO
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$VideoDTOImplCopyWith<_$VideoDTOImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
