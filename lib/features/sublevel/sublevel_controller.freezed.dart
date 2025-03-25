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
  bool get hasFinishedVideo => throw _privateConstructorUsedError;
  Set<String> get loadedLevelIds => throw _privateConstructorUsedError;
  Set<String> get loadingLevelIds => throw _privateConstructorUsedError;
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
      bool hasFinishedVideo,
      Set<String> loadedLevelIds,
      Set<String> loadingLevelIds,
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
    Object? hasFinishedVideo = null,
    Object? loadedLevelIds = null,
    Object? loadingLevelIds = null,
    Object? error = freezed,
  }) {
    return _then(_value.copyWith(
      sublevels: null == sublevels
          ? _value.sublevels
          : sublevels // ignore: cast_nullable_to_non_nullable
              as Set<SubLevel>,
      hasFinishedVideo: null == hasFinishedVideo
          ? _value.hasFinishedVideo
          : hasFinishedVideo // ignore: cast_nullable_to_non_nullable
              as bool,
      loadedLevelIds: null == loadedLevelIds
          ? _value.loadedLevelIds
          : loadedLevelIds // ignore: cast_nullable_to_non_nullable
              as Set<String>,
      loadingLevelIds: null == loadingLevelIds
          ? _value.loadingLevelIds
          : loadingLevelIds // ignore: cast_nullable_to_non_nullable
              as Set<String>,
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
      bool hasFinishedVideo,
      Set<String> loadedLevelIds,
      Set<String> loadingLevelIds,
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
    Object? hasFinishedVideo = null,
    Object? loadedLevelIds = null,
    Object? loadingLevelIds = null,
    Object? error = freezed,
  }) {
    return _then(_$SublevelControllerStateImpl(
      sublevels: null == sublevels
          ? _value._sublevels
          : sublevels // ignore: cast_nullable_to_non_nullable
              as Set<SubLevel>,
      hasFinishedVideo: null == hasFinishedVideo
          ? _value.hasFinishedVideo
          : hasFinishedVideo // ignore: cast_nullable_to_non_nullable
              as bool,
      loadedLevelIds: null == loadedLevelIds
          ? _value._loadedLevelIds
          : loadedLevelIds // ignore: cast_nullable_to_non_nullable
              as Set<String>,
      loadingLevelIds: null == loadingLevelIds
          ? _value._loadingLevelIds
          : loadingLevelIds // ignore: cast_nullable_to_non_nullable
              as Set<String>,
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
      this.hasFinishedVideo = false,
      final Set<String> loadedLevelIds = const {},
      final Set<String> loadingLevelIds = const {},
      this.error})
      : _sublevels = sublevels,
        _loadedLevelIds = loadedLevelIds,
        _loadingLevelIds = loadingLevelIds,
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
  final bool hasFinishedVideo;
  final Set<String> _loadedLevelIds;
  @override
  @JsonKey()
  Set<String> get loadedLevelIds {
    if (_loadedLevelIds is EqualUnmodifiableSetView) return _loadedLevelIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableSetView(_loadedLevelIds);
  }

  final Set<String> _loadingLevelIds;
  @override
  @JsonKey()
  Set<String> get loadingLevelIds {
    if (_loadingLevelIds is EqualUnmodifiableSetView) return _loadingLevelIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableSetView(_loadingLevelIds);
  }

  @override
  final String? error;

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'SublevelControllerState(sublevels: $sublevels, hasFinishedVideo: $hasFinishedVideo, loadedLevelIds: $loadedLevelIds, loadingLevelIds: $loadingLevelIds, error: $error)';
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty('type', 'SublevelControllerState'))
      ..add(DiagnosticsProperty('sublevels', sublevels))
      ..add(DiagnosticsProperty('hasFinishedVideo', hasFinishedVideo))
      ..add(DiagnosticsProperty('loadedLevelIds', loadedLevelIds))
      ..add(DiagnosticsProperty('loadingLevelIds', loadingLevelIds))
      ..add(DiagnosticsProperty('error', error));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SublevelControllerStateImpl &&
            const DeepCollectionEquality()
                .equals(other._sublevels, _sublevels) &&
            (identical(other.hasFinishedVideo, hasFinishedVideo) ||
                other.hasFinishedVideo == hasFinishedVideo) &&
            const DeepCollectionEquality()
                .equals(other._loadedLevelIds, _loadedLevelIds) &&
            const DeepCollectionEquality()
                .equals(other._loadingLevelIds, _loadingLevelIds) &&
            (identical(other.error, error) || other.error == error));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(_sublevels),
      hasFinishedVideo,
      const DeepCollectionEquality().hash(_loadedLevelIds),
      const DeepCollectionEquality().hash(_loadingLevelIds),
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
      final bool hasFinishedVideo,
      final Set<String> loadedLevelIds,
      final Set<String> loadingLevelIds,
      final String? error}) = _$SublevelControllerStateImpl;
  const _SublevelControllerState._() : super._();

  @override
  Set<SubLevel> get sublevels;
  @override
  bool get hasFinishedVideo;
  @override
  Set<String> get loadedLevelIds;
  @override
  Set<String> get loadingLevelIds;
  @override
  String? get error;

  /// Create a copy of SublevelControllerState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SublevelControllerStateImplCopyWith<_$SublevelControllerStateImpl>
      get copyWith => throw _privateConstructorUsedError;
}
