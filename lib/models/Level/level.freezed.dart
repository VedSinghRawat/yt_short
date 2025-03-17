// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'level.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Level _$LevelFromJson(Map<String, dynamic> json) {
  return _Level.fromJson(json);
}

/// @nodoc
mixin _$Level {
  String get id => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String? get nextId => throw _privateConstructorUsedError;
  String? get prevId => throw _privateConstructorUsedError;
  int get subLevelCount => throw _privateConstructorUsedError;

  /// Serializes this Level to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Level
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $LevelCopyWith<Level> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $LevelCopyWith<$Res> {
  factory $LevelCopyWith(Level value, $Res Function(Level) then) =
      _$LevelCopyWithImpl<$Res, Level>;
  @useResult
  $Res call(
      {String id,
      String title,
      String? nextId,
      String? prevId,
      int subLevelCount});
}

/// @nodoc
class _$LevelCopyWithImpl<$Res, $Val extends Level>
    implements $LevelCopyWith<$Res> {
  _$LevelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Level
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? nextId = freezed,
    Object? prevId = freezed,
    Object? subLevelCount = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      nextId: freezed == nextId
          ? _value.nextId
          : nextId // ignore: cast_nullable_to_non_nullable
              as String?,
      prevId: freezed == prevId
          ? _value.prevId
          : prevId // ignore: cast_nullable_to_non_nullable
              as String?,
      subLevelCount: null == subLevelCount
          ? _value.subLevelCount
          : subLevelCount // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$LevelImplCopyWith<$Res> implements $LevelCopyWith<$Res> {
  factory _$$LevelImplCopyWith(
          _$LevelImpl value, $Res Function(_$LevelImpl) then) =
      __$$LevelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String title,
      String? nextId,
      String? prevId,
      int subLevelCount});
}

/// @nodoc
class __$$LevelImplCopyWithImpl<$Res>
    extends _$LevelCopyWithImpl<$Res, _$LevelImpl>
    implements _$$LevelImplCopyWith<$Res> {
  __$$LevelImplCopyWithImpl(
      _$LevelImpl _value, $Res Function(_$LevelImpl) _then)
      : super(_value, _then);

  /// Create a copy of Level
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? nextId = freezed,
    Object? prevId = freezed,
    Object? subLevelCount = null,
  }) {
    return _then(_$LevelImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      nextId: freezed == nextId
          ? _value.nextId
          : nextId // ignore: cast_nullable_to_non_nullable
              as String?,
      prevId: freezed == prevId
          ? _value.prevId
          : prevId // ignore: cast_nullable_to_non_nullable
              as String?,
      subLevelCount: null == subLevelCount
          ? _value.subLevelCount
          : subLevelCount // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$LevelImpl with DiagnosticableTreeMixin implements _Level {
  const _$LevelImpl(
      {required this.id,
      required this.title,
      this.nextId,
      this.prevId,
      required this.subLevelCount});

  factory _$LevelImpl.fromJson(Map<String, dynamic> json) =>
      _$$LevelImplFromJson(json);

  @override
  final String id;
  @override
  final String title;
  @override
  final String? nextId;
  @override
  final String? prevId;
  @override
  final int subLevelCount;

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'Level(id: $id, title: $title, nextId: $nextId, prevId: $prevId, subLevelCount: $subLevelCount)';
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty('type', 'Level'))
      ..add(DiagnosticsProperty('id', id))
      ..add(DiagnosticsProperty('title', title))
      ..add(DiagnosticsProperty('nextId', nextId))
      ..add(DiagnosticsProperty('prevId', prevId))
      ..add(DiagnosticsProperty('subLevelCount', subLevelCount));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LevelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.nextId, nextId) || other.nextId == nextId) &&
            (identical(other.prevId, prevId) || other.prevId == prevId) &&
            (identical(other.subLevelCount, subLevelCount) ||
                other.subLevelCount == subLevelCount));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, id, title, nextId, prevId, subLevelCount);

  /// Create a copy of Level
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$LevelImplCopyWith<_$LevelImpl> get copyWith =>
      __$$LevelImplCopyWithImpl<_$LevelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$LevelImplToJson(
      this,
    );
  }
}

abstract class _Level implements Level {
  const factory _Level(
      {required final String id,
      required final String title,
      final String? nextId,
      final String? prevId,
      required final int subLevelCount}) = _$LevelImpl;

  factory _Level.fromJson(Map<String, dynamic> json) = _$LevelImpl.fromJson;

  @override
  String get id;
  @override
  String get title;
  @override
  String? get nextId;
  @override
  String? get prevId;
  @override
  int get subLevelCount;

  /// Create a copy of Level
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$LevelImplCopyWith<_$LevelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

LevelDTO _$LevelDTOFromJson(Map<String, dynamic> json) {
  return _LevelDTO.fromJson(json);
}

/// @nodoc
mixin _$LevelDTO {
  String get id => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String? get nextId => throw _privateConstructorUsedError;
  String? get prevId => throw _privateConstructorUsedError;
  List<SubLevelDTO> get subLevels => throw _privateConstructorUsedError;

  /// Serializes this LevelDTO to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of LevelDTO
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $LevelDTOCopyWith<LevelDTO> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $LevelDTOCopyWith<$Res> {
  factory $LevelDTOCopyWith(LevelDTO value, $Res Function(LevelDTO) then) =
      _$LevelDTOCopyWithImpl<$Res, LevelDTO>;
  @useResult
  $Res call(
      {String id,
      String title,
      String? nextId,
      String? prevId,
      List<SubLevelDTO> subLevels});
}

/// @nodoc
class _$LevelDTOCopyWithImpl<$Res, $Val extends LevelDTO>
    implements $LevelDTOCopyWith<$Res> {
  _$LevelDTOCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of LevelDTO
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? nextId = freezed,
    Object? prevId = freezed,
    Object? subLevels = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      nextId: freezed == nextId
          ? _value.nextId
          : nextId // ignore: cast_nullable_to_non_nullable
              as String?,
      prevId: freezed == prevId
          ? _value.prevId
          : prevId // ignore: cast_nullable_to_non_nullable
              as String?,
      subLevels: null == subLevels
          ? _value.subLevels
          : subLevels // ignore: cast_nullable_to_non_nullable
              as List<SubLevelDTO>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$LevelDTOImplCopyWith<$Res>
    implements $LevelDTOCopyWith<$Res> {
  factory _$$LevelDTOImplCopyWith(
          _$LevelDTOImpl value, $Res Function(_$LevelDTOImpl) then) =
      __$$LevelDTOImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String title,
      String? nextId,
      String? prevId,
      List<SubLevelDTO> subLevels});
}

/// @nodoc
class __$$LevelDTOImplCopyWithImpl<$Res>
    extends _$LevelDTOCopyWithImpl<$Res, _$LevelDTOImpl>
    implements _$$LevelDTOImplCopyWith<$Res> {
  __$$LevelDTOImplCopyWithImpl(
      _$LevelDTOImpl _value, $Res Function(_$LevelDTOImpl) _then)
      : super(_value, _then);

  /// Create a copy of LevelDTO
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? nextId = freezed,
    Object? prevId = freezed,
    Object? subLevels = null,
  }) {
    return _then(_$LevelDTOImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      nextId: freezed == nextId
          ? _value.nextId
          : nextId // ignore: cast_nullable_to_non_nullable
              as String?,
      prevId: freezed == prevId
          ? _value.prevId
          : prevId // ignore: cast_nullable_to_non_nullable
              as String?,
      subLevels: null == subLevels
          ? _value._subLevels
          : subLevels // ignore: cast_nullable_to_non_nullable
              as List<SubLevelDTO>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$LevelDTOImpl with DiagnosticableTreeMixin implements _LevelDTO {
  const _$LevelDTOImpl(
      {required this.id,
      required this.title,
      this.nextId,
      this.prevId,
      required final List<SubLevelDTO> subLevels})
      : _subLevels = subLevels;

  factory _$LevelDTOImpl.fromJson(Map<String, dynamic> json) =>
      _$$LevelDTOImplFromJson(json);

  @override
  final String id;
  @override
  final String title;
  @override
  final String? nextId;
  @override
  final String? prevId;
  final List<SubLevelDTO> _subLevels;
  @override
  List<SubLevelDTO> get subLevels {
    if (_subLevels is EqualUnmodifiableListView) return _subLevels;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_subLevels);
  }

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'LevelDTO(id: $id, title: $title, nextId: $nextId, prevId: $prevId, subLevels: $subLevels)';
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty('type', 'LevelDTO'))
      ..add(DiagnosticsProperty('id', id))
      ..add(DiagnosticsProperty('title', title))
      ..add(DiagnosticsProperty('nextId', nextId))
      ..add(DiagnosticsProperty('prevId', prevId))
      ..add(DiagnosticsProperty('subLevels', subLevels));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LevelDTOImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.nextId, nextId) || other.nextId == nextId) &&
            (identical(other.prevId, prevId) || other.prevId == prevId) &&
            const DeepCollectionEquality()
                .equals(other._subLevels, _subLevels));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, title, nextId, prevId,
      const DeepCollectionEquality().hash(_subLevels));

  /// Create a copy of LevelDTO
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$LevelDTOImplCopyWith<_$LevelDTOImpl> get copyWith =>
      __$$LevelDTOImplCopyWithImpl<_$LevelDTOImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$LevelDTOImplToJson(
      this,
    );
  }
}

abstract class _LevelDTO implements LevelDTO {
  const factory _LevelDTO(
      {required final String id,
      required final String title,
      final String? nextId,
      final String? prevId,
      required final List<SubLevelDTO> subLevels}) = _$LevelDTOImpl;

  factory _LevelDTO.fromJson(Map<String, dynamic> json) =
      _$LevelDTOImpl.fromJson;

  @override
  String get id;
  @override
  String get title;
  @override
  String? get nextId;
  @override
  String? get prevId;
  @override
  List<SubLevelDTO> get subLevels;

  /// Create a copy of LevelDTO
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$LevelDTOImplCopyWith<_$LevelDTOImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
