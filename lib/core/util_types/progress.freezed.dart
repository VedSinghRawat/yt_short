// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'progress.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Progress _$ProgressFromJson(Map<String, dynamic> json) {
  return _Progress.fromJson(json);
}

/// @nodoc
mixin _$Progress {
  int? get level => throw _privateConstructorUsedError;
  int? get subLevel => throw _privateConstructorUsedError;
  int? get maxLevel => throw _privateConstructorUsedError;
  int? get maxSubLevel => throw _privateConstructorUsedError;
  String? get levelId => throw _privateConstructorUsedError;
  int? get modified => throw _privateConstructorUsedError;

  /// Serializes this Progress to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Progress
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ProgressCopyWith<Progress> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ProgressCopyWith<$Res> {
  factory $ProgressCopyWith(Progress value, $Res Function(Progress) then) =
      _$ProgressCopyWithImpl<$Res, Progress>;
  @useResult
  $Res call(
      {int? level,
      int? subLevel,
      int? maxLevel,
      int? maxSubLevel,
      String? levelId,
      int? modified});
}

/// @nodoc
class _$ProgressCopyWithImpl<$Res, $Val extends Progress>
    implements $ProgressCopyWith<$Res> {
  _$ProgressCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Progress
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? level = freezed,
    Object? subLevel = freezed,
    Object? maxLevel = freezed,
    Object? maxSubLevel = freezed,
    Object? levelId = freezed,
    Object? modified = freezed,
  }) {
    return _then(_value.copyWith(
      level: freezed == level
          ? _value.level
          : level // ignore: cast_nullable_to_non_nullable
              as int?,
      subLevel: freezed == subLevel
          ? _value.subLevel
          : subLevel // ignore: cast_nullable_to_non_nullable
              as int?,
      maxLevel: freezed == maxLevel
          ? _value.maxLevel
          : maxLevel // ignore: cast_nullable_to_non_nullable
              as int?,
      maxSubLevel: freezed == maxSubLevel
          ? _value.maxSubLevel
          : maxSubLevel // ignore: cast_nullable_to_non_nullable
              as int?,
      levelId: freezed == levelId
          ? _value.levelId
          : levelId // ignore: cast_nullable_to_non_nullable
              as String?,
      modified: freezed == modified
          ? _value.modified
          : modified // ignore: cast_nullable_to_non_nullable
              as int?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ProgressImplCopyWith<$Res>
    implements $ProgressCopyWith<$Res> {
  factory _$$ProgressImplCopyWith(
          _$ProgressImpl value, $Res Function(_$ProgressImpl) then) =
      __$$ProgressImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int? level,
      int? subLevel,
      int? maxLevel,
      int? maxSubLevel,
      String? levelId,
      int? modified});
}

/// @nodoc
class __$$ProgressImplCopyWithImpl<$Res>
    extends _$ProgressCopyWithImpl<$Res, _$ProgressImpl>
    implements _$$ProgressImplCopyWith<$Res> {
  __$$ProgressImplCopyWithImpl(
      _$ProgressImpl _value, $Res Function(_$ProgressImpl) _then)
      : super(_value, _then);

  /// Create a copy of Progress
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? level = freezed,
    Object? subLevel = freezed,
    Object? maxLevel = freezed,
    Object? maxSubLevel = freezed,
    Object? levelId = freezed,
    Object? modified = freezed,
  }) {
    return _then(_$ProgressImpl(
      level: freezed == level
          ? _value.level
          : level // ignore: cast_nullable_to_non_nullable
              as int?,
      subLevel: freezed == subLevel
          ? _value.subLevel
          : subLevel // ignore: cast_nullable_to_non_nullable
              as int?,
      maxLevel: freezed == maxLevel
          ? _value.maxLevel
          : maxLevel // ignore: cast_nullable_to_non_nullable
              as int?,
      maxSubLevel: freezed == maxSubLevel
          ? _value.maxSubLevel
          : maxSubLevel // ignore: cast_nullable_to_non_nullable
              as int?,
      levelId: freezed == levelId
          ? _value.levelId
          : levelId // ignore: cast_nullable_to_non_nullable
              as String?,
      modified: freezed == modified
          ? _value.modified
          : modified // ignore: cast_nullable_to_non_nullable
              as int?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ProgressImpl extends _Progress with DiagnosticableTreeMixin {
  const _$ProgressImpl(
      {this.level,
      this.subLevel,
      this.maxLevel,
      this.maxSubLevel,
      this.levelId,
      this.modified})
      : super._();

  factory _$ProgressImpl.fromJson(Map<String, dynamic> json) =>
      _$$ProgressImplFromJson(json);

  @override
  final int? level;
  @override
  final int? subLevel;
  @override
  final int? maxLevel;
  @override
  final int? maxSubLevel;
  @override
  final String? levelId;
  @override
  final int? modified;

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'Progress(level: $level, subLevel: $subLevel, maxLevel: $maxLevel, maxSubLevel: $maxSubLevel, levelId: $levelId, modified: $modified)';
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty('type', 'Progress'))
      ..add(DiagnosticsProperty('level', level))
      ..add(DiagnosticsProperty('subLevel', subLevel))
      ..add(DiagnosticsProperty('maxLevel', maxLevel))
      ..add(DiagnosticsProperty('maxSubLevel', maxSubLevel))
      ..add(DiagnosticsProperty('levelId', levelId))
      ..add(DiagnosticsProperty('modified', modified));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ProgressImpl &&
            (identical(other.level, level) || other.level == level) &&
            (identical(other.subLevel, subLevel) ||
                other.subLevel == subLevel) &&
            (identical(other.maxLevel, maxLevel) ||
                other.maxLevel == maxLevel) &&
            (identical(other.maxSubLevel, maxSubLevel) ||
                other.maxSubLevel == maxSubLevel) &&
            (identical(other.levelId, levelId) || other.levelId == levelId) &&
            (identical(other.modified, modified) ||
                other.modified == modified));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, level, subLevel, maxLevel, maxSubLevel, levelId, modified);

  /// Create a copy of Progress
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ProgressImplCopyWith<_$ProgressImpl> get copyWith =>
      __$$ProgressImplCopyWithImpl<_$ProgressImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ProgressImplToJson(
      this,
    );
  }
}

abstract class _Progress extends Progress {
  const factory _Progress(
      {final int? level,
      final int? subLevel,
      final int? maxLevel,
      final int? maxSubLevel,
      final String? levelId,
      final int? modified}) = _$ProgressImpl;
  const _Progress._() : super._();

  factory _Progress.fromJson(Map<String, dynamic> json) =
      _$ProgressImpl.fromJson;

  @override
  int? get level;
  @override
  int? get subLevel;
  @override
  int? get maxLevel;
  @override
  int? get maxSubLevel;
  @override
  String? get levelId;
  @override
  int? get modified;

  /// Create a copy of Progress
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ProgressImplCopyWith<_$ProgressImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
