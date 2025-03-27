// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'api_service.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$ApiParams {
  String get endpoint => throw _privateConstructorUsedError;
  ApiMethod get method => throw _privateConstructorUsedError;
  Map<String, dynamic>? get body => throw _privateConstructorUsedError;
  Map<String, String>? get headers => throw _privateConstructorUsedError;
  String? get customBaseUrl => throw _privateConstructorUsedError;
  ResponseType? get responseType => throw _privateConstructorUsedError;

  /// Create a copy of ApiParams
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ApiParamsCopyWith<ApiParams> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ApiParamsCopyWith<$Res> {
  factory $ApiParamsCopyWith(ApiParams value, $Res Function(ApiParams) then) =
      _$ApiParamsCopyWithImpl<$Res, ApiParams>;
  @useResult
  $Res call(
      {String endpoint,
      ApiMethod method,
      Map<String, dynamic>? body,
      Map<String, String>? headers,
      String? customBaseUrl,
      ResponseType? responseType});
}

/// @nodoc
class _$ApiParamsCopyWithImpl<$Res, $Val extends ApiParams>
    implements $ApiParamsCopyWith<$Res> {
  _$ApiParamsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ApiParams
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? endpoint = null,
    Object? method = null,
    Object? body = freezed,
    Object? headers = freezed,
    Object? customBaseUrl = freezed,
    Object? responseType = freezed,
  }) {
    return _then(_value.copyWith(
      endpoint: null == endpoint
          ? _value.endpoint
          : endpoint // ignore: cast_nullable_to_non_nullable
              as String,
      method: null == method
          ? _value.method
          : method // ignore: cast_nullable_to_non_nullable
              as ApiMethod,
      body: freezed == body
          ? _value.body
          : body // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
      headers: freezed == headers
          ? _value.headers
          : headers // ignore: cast_nullable_to_non_nullable
              as Map<String, String>?,
      customBaseUrl: freezed == customBaseUrl
          ? _value.customBaseUrl
          : customBaseUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      responseType: freezed == responseType
          ? _value.responseType
          : responseType // ignore: cast_nullable_to_non_nullable
              as ResponseType?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ApiParamsImplCopyWith<$Res>
    implements $ApiParamsCopyWith<$Res> {
  factory _$$ApiParamsImplCopyWith(
          _$ApiParamsImpl value, $Res Function(_$ApiParamsImpl) then) =
      __$$ApiParamsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String endpoint,
      ApiMethod method,
      Map<String, dynamic>? body,
      Map<String, String>? headers,
      String? customBaseUrl,
      ResponseType? responseType});
}

/// @nodoc
class __$$ApiParamsImplCopyWithImpl<$Res>
    extends _$ApiParamsCopyWithImpl<$Res, _$ApiParamsImpl>
    implements _$$ApiParamsImplCopyWith<$Res> {
  __$$ApiParamsImplCopyWithImpl(
      _$ApiParamsImpl _value, $Res Function(_$ApiParamsImpl) _then)
      : super(_value, _then);

  /// Create a copy of ApiParams
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? endpoint = null,
    Object? method = null,
    Object? body = freezed,
    Object? headers = freezed,
    Object? customBaseUrl = freezed,
    Object? responseType = freezed,
  }) {
    return _then(_$ApiParamsImpl(
      endpoint: null == endpoint
          ? _value.endpoint
          : endpoint // ignore: cast_nullable_to_non_nullable
              as String,
      method: null == method
          ? _value.method
          : method // ignore: cast_nullable_to_non_nullable
              as ApiMethod,
      body: freezed == body
          ? _value._body
          : body // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
      headers: freezed == headers
          ? _value._headers
          : headers // ignore: cast_nullable_to_non_nullable
              as Map<String, String>?,
      customBaseUrl: freezed == customBaseUrl
          ? _value.customBaseUrl
          : customBaseUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      responseType: freezed == responseType
          ? _value.responseType
          : responseType // ignore: cast_nullable_to_non_nullable
              as ResponseType?,
    ));
  }
}

/// @nodoc

class _$ApiParamsImpl implements _ApiParams {
  const _$ApiParamsImpl(
      {required this.endpoint,
      required this.method,
      final Map<String, dynamic>? body,
      final Map<String, String>? headers,
      this.customBaseUrl,
      this.responseType})
      : _body = body,
        _headers = headers;

  @override
  final String endpoint;
  @override
  final ApiMethod method;
  final Map<String, dynamic>? _body;
  @override
  Map<String, dynamic>? get body {
    final value = _body;
    if (value == null) return null;
    if (_body is EqualUnmodifiableMapView) return _body;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  final Map<String, String>? _headers;
  @override
  Map<String, String>? get headers {
    final value = _headers;
    if (value == null) return null;
    if (_headers is EqualUnmodifiableMapView) return _headers;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  @override
  final String? customBaseUrl;
  @override
  final ResponseType? responseType;

  @override
  String toString() {
    return 'ApiParams(endpoint: $endpoint, method: $method, body: $body, headers: $headers, customBaseUrl: $customBaseUrl, responseType: $responseType)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ApiParamsImpl &&
            (identical(other.endpoint, endpoint) ||
                other.endpoint == endpoint) &&
            (identical(other.method, method) || other.method == method) &&
            const DeepCollectionEquality().equals(other._body, _body) &&
            const DeepCollectionEquality().equals(other._headers, _headers) &&
            (identical(other.customBaseUrl, customBaseUrl) ||
                other.customBaseUrl == customBaseUrl) &&
            (identical(other.responseType, responseType) ||
                other.responseType == responseType));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      endpoint,
      method,
      const DeepCollectionEquality().hash(_body),
      const DeepCollectionEquality().hash(_headers),
      customBaseUrl,
      responseType);

  /// Create a copy of ApiParams
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ApiParamsImplCopyWith<_$ApiParamsImpl> get copyWith =>
      __$$ApiParamsImplCopyWithImpl<_$ApiParamsImpl>(this, _$identity);
}

abstract class _ApiParams implements ApiParams {
  const factory _ApiParams(
      {required final String endpoint,
      required final ApiMethod method,
      final Map<String, dynamic>? body,
      final Map<String, String>? headers,
      final String? customBaseUrl,
      final ResponseType? responseType}) = _$ApiParamsImpl;

  @override
  String get endpoint;
  @override
  ApiMethod get method;
  @override
  Map<String, dynamic>? get body;
  @override
  Map<String, String>? get headers;
  @override
  String? get customBaseUrl;
  @override
  ResponseType? get responseType;

  /// Create a copy of ApiParams
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ApiParamsImplCopyWith<_$ApiParamsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
