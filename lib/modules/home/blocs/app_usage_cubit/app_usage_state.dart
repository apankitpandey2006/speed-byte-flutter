part of 'app_usage_cubit.dart';

@freezed
class AppUsageState with _$AppUsageState {
  const factory AppUsageState({
    @Default(false) bool isAppUsagePermissionGranted,
    @Default(false) bool isLoading,
    @Default({}) Map<String, List<AppUsage>> appUsageByDate,
  }) = _AppUsageState;

  factory AppUsageState.initial() => const AppUsageState(
      appUsageByDate: {}, isAppUsagePermissionGranted: false, isLoading: false);
}
