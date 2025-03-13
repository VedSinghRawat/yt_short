// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'sublevel_controller.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$SublevelControllerState {
  Map<String, SubLevel> get sublevelMap => throw _privateConstructorUsedError;
  Map<int, int> get subLevelCountByLevel => throw _privateConstructorUsedError;
  bool? get loading => throw _privateConstructorUsedError;
  bool get hasFinishedVideo => throw _privateConstructorUsedError;
  Level? get currentLevel => throw _privateConstructorUsedError;

  /// Create a copy of SublevelControllerState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SublevelControllerStateCopyWith<SublevelControllerState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SublevelControllerStateCopyWith<$Res> {
  factory $SublevelControllerStateCopyWith(SublevelControllerState value,
          $Res Function(SublevelControllerState) then) =
      _$SublevelControllerStateCopyWithImpl<$Res, SublevelControllerState>;
  @useResult
  $Res call(
      {Map<String, SubLevel> sublevelMap,
      Map<int, int> subLevelCountByLevel,
      bool? loading,
      bool hasFinishedVideo,
      Level? currentLevel});

  $LevelCopyWith<$Res>? get currentLevel;
}

/// @nodoc
class _$SublevelControllerStateCopyWithImpl<$Res,
        $Val extends SublevelControllerState>
    implements $SublevelControllerStateCopyWith<$Res> {
  _$SublevelControllerStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SublevelControllerState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? sublevelMap = null,
    Object? subLevelCountByLevel = null,
    Object? loading = freezed,
    Object? hasFinishedVideo = null,
    Object? currentLevel = freezed,
  }) {
    return _then(_value.copyWith(
      sublevelMap: null == sublevelMap
          ? _value.sublevelMap
          : sublevelMap // ignore: cast_nullable_to_non_nullable
              as Map<String, SubLevel>,
      subLevelCountByLevel: null == subLevelCountByLevel
          ? _value.subLevelCountByLevel
          : subLevelCountByLevel // ignore: cast_nullable_to_non_nullable
              as Map<int, int>,
      loading: freezed == loading
          ? _value.loading
          : loading // ignore: cast_nullable_to_non_nullable
              as bool?,
      hasFinishedVideo: null == hasFinishedVideo
          ? _value.hasFinishedVideo
          : hasFinishedVideo // ignore: cast_nullable_to_non_nullable
              as bool,
      currentLevel: freezed == currentLevel
          ? _value.currentLevel
          : currentLevel // ignore: cast_nullable_to_non_nullable
              as Level?,
    ) as $Val);
  }

  /// Create a copy of SublevelControllerState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $LevelCopyWith<$Res>? get currentLevel {
    if (_value.currentLevel == null) {
      return null;
    }

    return $LevelCopyWith<$Res>(_value.currentLevel!, (value) {
      return _then(_value.copyWith(currentLevel: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$SublevelControllerStateImplCopyWith<$Res>
    implements $SublevelControllerStateCopyWith<$Res> {
  factory _$$SublevelControllerStateImplCopyWith(
          _$SublevelControllerStateImpl value,
          $Res Function(_$SublevelControllerStateImpl) then) =
      __$$SublevelControllerStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {Map<String, SubLevel> sublevelMap,
      Map<int, int> subLevelCountByLevel,
      bool? loading,
      bool hasFinishedVideo,
      Level? currentLevel});

  @override
  $LevelCopyWith<$Res>? get currentLevel;
}

/// @nodoc
class __$$SublevelControllerStateImplCopyWithImpl<$Res>
    extends _$SublevelControllerStateCopyWithImpl<$Res,
        _$SublevelControllerStateImpl>
    implements _$$SublevelControllerStateImplCopyWith<$Res> {
  __$$SublevelControllerStateImplCopyWithImpl(
      _$SublevelControllerStateImpl _value,
      $Res Function(_$SublevelControllerStateImpl) _then)
      : super(_value, _then);

  /// Create a copy of SublevelControllerState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? sublevelMap = null,
    Object? subLevelCountByLevel = null,
    Object? loading = freezed,
    Object? hasFinishedVideo = null,
    Object? currentLevel = freezed,
  }) {
    return _then(_$SublevelControllerStateImpl(
      sublevelMap: null == sublevelMap
          ? _value._sublevelMap
          : sublevelMap // ignore: cast_nullable_to_non_nullable
              as Map<String, SubLevel>,
      subLevelCountByLevel: null == subLevelCountByLevel
          ? _value._subLevelCountByLevel
          : subLevelCountByLevel // ignore: cast_nullable_to_non_nullable
              as Map<int, int>,
      loading: freezed == loading
          ? _value.loading
          : loading // ignore: cast_nullable_to_non_nullable
              as bool?,
      hasFinishedVideo: null == hasFinishedVideo
          ? _value.hasFinishedVideo
          : hasFinishedVideo // ignore: cast_nullable_to_non_nullable
              as bool,
      currentLevel: freezed == currentLevel
          ? _value.currentLevel
          : currentLevel // ignore: cast_nullable_to_non_nullable
              as Level?,
    ));
  }
}

/// @nodoc

class _$SublevelControllerStateImpl
    with DiagnosticableTreeMixin
    implements _SublevelControllerState {
  const _$SublevelControllerStateImpl(
      {final Map<String, SubLevel> sublevelMap = const {},
      final Map<int, int> subLevelCountByLevel = const {},
      this.loading,
      this.hasFinishedVideo = false,
      this.currentLevel})
      : _sublevelMap = sublevelMap,
        _subLevelCountByLevel = subLevelCountByLevel;

  final Map<String, SubLevel> _sublevelMap;
  @override
  @JsonKey()
  Map<String, SubLevel> get sublevelMap {
    if (_sublevelMap is EqualUnmodifiableMapView) return _sublevelMap;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_sublevelMap);
  }

  final Map<int, int> _subLevelCountByLevel;
  @override
  @JsonKey()
  Map<int, int> get subLevelCountByLevel {
    if (_subLevelCountByLevel is EqualUnmodifiableMapView)
      return _subLevelCountByLevel;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_subLevelCountByLevel);
  }

  @override
  final bool? loading;
  @override
  @JsonKey()
  final bool hasFinishedVideo;
  @override
  final Level? currentLevel;

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'SublevelControllerState(sublevelMap: $sublevelMap, subLevelCountByLevel: $subLevelCountByLevel, loading: $loading, hasFinishedVideo: $hasFinishedVideo, currentLevel: $currentLevel)';
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty('type', 'SublevelControllerState'))
      ..add(DiagnosticsProperty('sublevelMap', sublevelMap))
      ..add(DiagnosticsProperty('subLevelCountByLevel', subLevelCountByLevel))
      ..add(DiagnosticsProperty('loading', loading))
      ..add(DiagnosticsProperty('hasFinishedVideo', hasFinishedVideo))
      ..add(DiagnosticsProperty('currentLevel', currentLevel));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SublevelControllerStateImpl &&
            const DeepCollectionEquality()
                .equals(other._sublevelMap, _sublevelMap) &&
            const DeepCollectionEquality()
                .equals(other._subLevelCountByLevel, _subLevelCountByLevel) &&
            (identical(other.loading, loading) || other.loading == loading) &&
            (identical(other.hasFinishedVideo, hasFinishedVideo) ||
                other.hasFinishedVideo == hasFinishedVideo) &&
            (identical(other.currentLevel, currentLevel) ||
                other.currentLevel == currentLevel));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(_sublevelMap),
      const DeepCollectionEquality().hash(_subLevelCountByLevel),
      loading,
      hasFinishedVideo,
      currentLevel);

  /// Create a copy of SublevelControllerState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SublevelControllerStateImplCopyWith<_$SublevelControllerStateImpl>
      get copyWith => __$$SublevelControllerStateImplCopyWithImpl<
          _$SublevelControllerStateImpl>(this, _$identity);
}

abstract class _SublevelControllerState implements SublevelControllerState {
  const factory _SublevelControllerState(
      {final Map<String, SubLevel> sublevelMap,
      final Map<int, int> subLevelCountByLevel,
      final bool? loading,
      final bool hasFinishedVideo,
      final Level? currentLevel}) = _$SublevelControllerStateImpl;

  @override
  Map<String, SubLevel> get sublevelMap;
  @override
  Map<int, int> get subLevelCountByLevel;
  @override
  bool? get loading;
  @override
  bool get hasFinishedVideo;
  @override
  Level? get currentLevel;

  /// Create a copy of SublevelControllerState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SublevelControllerStateImplCopyWith<_$SublevelControllerStateImpl>
      get copyWith => throw _privateConstructorUsedError;
}
