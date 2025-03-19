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
  Set<SubLevel> get sublevels => throw _privateConstructorUsedError;
  bool get loading => throw _privateConstructorUsedError;
  bool get hasFinishedVideo => throw _privateConstructorUsedError;
  List<String> get levelIds => throw _privateConstructorUsedError;
  String? get error => throw _privateConstructorUsedError;

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
      {Set<SubLevel> sublevels,
      bool loading,
      bool hasFinishedVideo,
      List<String> levelIds,
      String? error});
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
    Object? sublevels = null,
    Object? loading = null,
    Object? hasFinishedVideo = null,
    Object? levelIds = null,
    Object? error = freezed,
  }) {
    return _then(_value.copyWith(
      sublevels: null == sublevels
          ? _value.sublevels
          : sublevels // ignore: cast_nullable_to_non_nullable
              as Set<SubLevel>,
      loading: null == loading
          ? _value.loading
          : loading // ignore: cast_nullable_to_non_nullable
              as bool,
      hasFinishedVideo: null == hasFinishedVideo
          ? _value.hasFinishedVideo
          : hasFinishedVideo // ignore: cast_nullable_to_non_nullable
              as bool,
      levelIds: null == levelIds
          ? _value.levelIds
          : levelIds // ignore: cast_nullable_to_non_nullable
              as List<String>,
      error: freezed == error
          ? _value.error
          : error // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
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
      {Set<SubLevel> sublevels,
      bool loading,
      bool hasFinishedVideo,
      List<String> levelIds,
      String? error});
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
    Object? sublevels = null,
    Object? loading = null,
    Object? hasFinishedVideo = null,
    Object? levelIds = null,
    Object? error = freezed,
  }) {
    return _then(_$SublevelControllerStateImpl(
      sublevels: null == sublevels
          ? _value._sublevels
          : sublevels // ignore: cast_nullable_to_non_nullable
              as Set<SubLevel>,
      loading: null == loading
          ? _value.loading
          : loading // ignore: cast_nullable_to_non_nullable
              as bool,
      hasFinishedVideo: null == hasFinishedVideo
          ? _value.hasFinishedVideo
          : hasFinishedVideo // ignore: cast_nullable_to_non_nullable
              as bool,
      levelIds: null == levelIds
          ? _value._levelIds
          : levelIds // ignore: cast_nullable_to_non_nullable
              as List<String>,
      error: freezed == error
          ? _value.error
          : error // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc

class _$SublevelControllerStateImpl extends _SublevelControllerState
    with DiagnosticableTreeMixin {
  const _$SublevelControllerStateImpl(
      {final Set<SubLevel> sublevels = const {},
      this.loading = true,
      this.hasFinishedVideo = false,
      final List<String> levelIds = const [],
      this.error})
      : _sublevels = sublevels,
        _levelIds = levelIds,
        super._();

  final Set<SubLevel> _sublevels;
  @override
  @JsonKey()
  Set<SubLevel> get sublevels {
    if (_sublevels is EqualUnmodifiableSetView) return _sublevels;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableSetView(_sublevels);
  }

  @override
  @JsonKey()
  final bool loading;
  @override
  @JsonKey()
  final bool hasFinishedVideo;
  final List<String> _levelIds;
  @override
  @JsonKey()
  List<String> get levelIds {
    if (_levelIds is EqualUnmodifiableListView) return _levelIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_levelIds);
  }

  @override
  final String? error;

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'SublevelControllerState(sublevels: $sublevels, loading: $loading, hasFinishedVideo: $hasFinishedVideo, levelIds: $levelIds, error: $error)';
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty('type', 'SublevelControllerState'))
      ..add(DiagnosticsProperty('sublevels', sublevels))
      ..add(DiagnosticsProperty('loading', loading))
      ..add(DiagnosticsProperty('hasFinishedVideo', hasFinishedVideo))
      ..add(DiagnosticsProperty('levelIds', levelIds))
      ..add(DiagnosticsProperty('error', error));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SublevelControllerStateImpl &&
            const DeepCollectionEquality()
                .equals(other._sublevels, _sublevels) &&
            (identical(other.loading, loading) || other.loading == loading) &&
            (identical(other.hasFinishedVideo, hasFinishedVideo) ||
                other.hasFinishedVideo == hasFinishedVideo) &&
            const DeepCollectionEquality().equals(other._levelIds, _levelIds) &&
            (identical(other.error, error) || other.error == error));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(_sublevels),
      loading,
      hasFinishedVideo,
      const DeepCollectionEquality().hash(_levelIds),
      error);

  /// Create a copy of SublevelControllerState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SublevelControllerStateImplCopyWith<_$SublevelControllerStateImpl>
      get copyWith => __$$SublevelControllerStateImplCopyWithImpl<
          _$SublevelControllerStateImpl>(this, _$identity);
}

abstract class _SublevelControllerState extends SublevelControllerState {
  const factory _SublevelControllerState(
      {final Set<SubLevel> sublevels,
      final bool loading,
      final bool hasFinishedVideo,
      final List<String> levelIds,
      final String? error}) = _$SublevelControllerStateImpl;
  const _SublevelControllerState._() : super._();

  @override
  Set<SubLevel> get sublevels;
  @override
  bool get loading;
  @override
  bool get hasFinishedVideo;
  @override
  List<String> get levelIds;
  @override
  String? get error;

  /// Create a copy of SublevelControllerState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SublevelControllerStateImplCopyWith<_$SublevelControllerStateImpl>
      get copyWith => throw _privateConstructorUsedError;
}
