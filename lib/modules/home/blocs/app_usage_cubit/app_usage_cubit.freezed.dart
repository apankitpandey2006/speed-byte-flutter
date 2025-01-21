// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'app_usage_cubit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$AppUsageState {
  bool get isAppUsagePermissionGranted => throw _privateConstructorUsedError;
  bool get isLoading => throw _privateConstructorUsedError;
  Map<String, List<AppUsage>> get appUsageByDate =>
      throw _privateConstructorUsedError;

  /// Create a copy of AppUsageState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AppUsageStateCopyWith<AppUsageState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AppUsageStateCopyWith<$Res> {
  factory $AppUsageStateCopyWith(
          AppUsageState value, $Res Function(AppUsageState) then) =
      _$AppUsageStateCopyWithImpl<$Res, AppUsageState>;
  @useResult
  $Res call(
      {bool isAppUsagePermissionGranted,
      bool isLoading,
      Map<String, List<AppUsage>> appUsageByDate});
}

/// @nodoc
class _$AppUsageStateCopyWithImpl<$Res, $Val extends AppUsageState>
    implements $AppUsageStateCopyWith<$Res> {
  _$AppUsageStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AppUsageState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isAppUsagePermissionGranted = null,
    Object? isLoading = null,
    Object? appUsageByDate = null,
  }) {
    return _then(_value.copyWith(
      isAppUsagePermissionGranted: null == isAppUsagePermissionGranted
          ? _value.isAppUsagePermissionGranted
          : isAppUsagePermissionGranted // ignore: cast_nullable_to_non_nullable
              as bool,
      isLoading: null == isLoading
          ? _value.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      appUsageByDate: null == appUsageByDate
          ? _value.appUsageByDate
          : appUsageByDate // ignore: cast_nullable_to_non_nullable
              as Map<String, List<AppUsage>>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$AppUsageStateImplCopyWith<$Res>
    implements $AppUsageStateCopyWith<$Res> {
  factory _$$AppUsageStateImplCopyWith(
          _$AppUsageStateImpl value, $Res Function(_$AppUsageStateImpl) then) =
      __$$AppUsageStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {bool isAppUsagePermissionGranted,
      bool isLoading,
      Map<String, List<AppUsage>> appUsageByDate});
}

/// @nodoc
class __$$AppUsageStateImplCopyWithImpl<$Res>
    extends _$AppUsageStateCopyWithImpl<$Res, _$AppUsageStateImpl>
    implements _$$AppUsageStateImplCopyWith<$Res> {
  __$$AppUsageStateImplCopyWithImpl(
      _$AppUsageStateImpl _value, $Res Function(_$AppUsageStateImpl) _then)
      : super(_value, _then);

  /// Create a copy of AppUsageState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isAppUsagePermissionGranted = null,
    Object? isLoading = null,
    Object? appUsageByDate = null,
  }) {
    return _then(_$AppUsageStateImpl(
      isAppUsagePermissionGranted: null == isAppUsagePermissionGranted
          ? _value.isAppUsagePermissionGranted
          : isAppUsagePermissionGranted // ignore: cast_nullable_to_non_nullable
              as bool,
      isLoading: null == isLoading
          ? _value.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      appUsageByDate: null == appUsageByDate
          ? _value._appUsageByDate
          : appUsageByDate // ignore: cast_nullable_to_non_nullable
              as Map<String, List<AppUsage>>,
    ));
  }
}

/// @nodoc

class _$AppUsageStateImpl implements _AppUsageState {
  const _$AppUsageStateImpl(
      {this.isAppUsagePermissionGranted = false,
      this.isLoading = false,
      final Map<String, List<AppUsage>> appUsageByDate = const {}})
      : _appUsageByDate = appUsageByDate;

  @override
  @JsonKey()
  final bool isAppUsagePermissionGranted;
  @override
  @JsonKey()
  final bool isLoading;
  final Map<String, List<AppUsage>> _appUsageByDate;
  @override
  @JsonKey()
  Map<String, List<AppUsage>> get appUsageByDate {
    if (_appUsageByDate is EqualUnmodifiableMapView) return _appUsageByDate;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_appUsageByDate);
  }

  @override
  String toString() {
    return 'AppUsageState(isAppUsagePermissionGranted: $isAppUsagePermissionGranted, isLoading: $isLoading, appUsageByDate: $appUsageByDate)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AppUsageStateImpl &&
            (identical(other.isAppUsagePermissionGranted,
                    isAppUsagePermissionGranted) ||
                other.isAppUsagePermissionGranted ==
                    isAppUsagePermissionGranted) &&
            (identical(other.isLoading, isLoading) ||
                other.isLoading == isLoading) &&
            const DeepCollectionEquality()
                .equals(other._appUsageByDate, _appUsageByDate));
  }

  @override
  int get hashCode => Object.hash(runtimeType, isAppUsagePermissionGranted,
      isLoading, const DeepCollectionEquality().hash(_appUsageByDate));

  /// Create a copy of AppUsageState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AppUsageStateImplCopyWith<_$AppUsageStateImpl> get copyWith =>
      __$$AppUsageStateImplCopyWithImpl<_$AppUsageStateImpl>(this, _$identity);
}

abstract class _AppUsageState implements AppUsageState {
  const factory _AppUsageState(
      {final bool isAppUsagePermissionGranted,
      final bool isLoading,
      final Map<String, List<AppUsage>> appUsageByDate}) = _$AppUsageStateImpl;

  @override
  bool get isAppUsagePermissionGranted;
  @override
  bool get isLoading;
  @override
  Map<String, List<AppUsage>> get appUsageByDate;

  /// Create a copy of AppUsageState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AppUsageStateImplCopyWith<_$AppUsageStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
