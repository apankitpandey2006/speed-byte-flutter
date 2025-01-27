import 'dart:convert';

import 'package:android_package_manager/android_package_manager.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:usage_stats/usage_stats.dart';

import '../../../../main.dart';
import '../../../../models/app_event.dart';
import '../../../../models/app_usage.dart';
import '../../../../utils/app_utils.dart';

part 'app_usage_cubit.freezed.dart';
part 'app_usage_state.dart';

class AppUsageCubit extends Cubit<AppUsageState> {
  AppUsageCubit() : super(AppUsageState.initial()) {
    _deviceInfoPlugin = DeviceInfoPlugin();
    _androidPackageManager = AndroidPackageManager();
  }

  late DeviceInfoPlugin _deviceInfoPlugin;
  late AndroidPackageManager _androidPackageManager;
  late String _deviceId;

  final Map<int, String> eventTypeMap = {
    1: 'Activity Resumed',
    2: 'Activity Paused',
    3: 'Activity Stopped',
  };

  final List<String> eventTypeForDurationList = [
    'Activity Resumed',
    'Activity Paused',
    'Activity Stopped',
  ];

  final List<String> _trackedPackages = [
    'com.example.alphabet_app',
    'com.example.varnmala_app',
    'com.DivineLab.Alphabet_BlackWhite',
    'com.DivineLab.Varnamala',
  ];

  Future<bool> checkPermission() async {
    emit(state.copyWith(isLoading: true));
    final isAppUsagePermissionGranted = await UsageStats.checkUsagePermission();
    if (isAppUsagePermissionGranted == null ||
        isAppUsagePermissionGranted == false) {
      await UsageStats.grantUsagePermission();
      emit(state.copyWith(isAppUsagePermissionGranted: true, isLoading: false));
      return false;
    } else {
      emit(state.copyWith(isAppUsagePermissionGranted: true, isLoading: false));
      return true;
    }
  }

  Future<void> sendDeviceInfoToApi() async {
    final deviceInfo = await _deviceInfoPlugin.androidInfo;

    final url = Uri.parse('https://speed-byte.onrender.com/devices');
    final dataToSend = {
      'device_name': deviceInfo.model,
      'android_id': deviceInfo.id,
    };

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(dataToSend),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        scaffoldStateKey.currentState?.showSnackBar(
          SnackBar(content: Text('${DateTime.now()}')),
        );
      } else {
        scaffoldStateKey.currentState?.showSnackBar(
          SnackBar(
              content: Text(
                  'Failed to send device info. Status: ${response.reasonPhrase} ${response.statusCode}')),
        );
      }
    } catch (e) {
      scaffoldStateKey.currentState?.showSnackBar(
        SnackBar(content: Text('Error sending device info: $e')),
      );
    }
  }

  Future<void> getAllAppUsageInfo() async {
    final startDate = DateTime.now().subtract(const Duration(days: 1));
    final endDate = DateTime.now();

    emit(state.copyWith(isLoading: true, appUsageByDate: {}));
    List<EventUsageInfo> queryEvents =
        await UsageStats.queryEvents(startDate, endDate);

    Map<String, List<AppEvent>> appNameToAppEventMap = {};
    Map<String, List<AppUsage>> appUsageByDate = {};

    var defaultIcon = await AppUtils.loadIcon("default-icon.png");

    for (var event in queryEvents) {
      var packageName = event.packageName;
      if (!AppUtils.isAndroidPackageNamePresent(
          _trackedPackages, packageName ?? "")) {
        continue;
      }

      var eventType = eventTypeMap[int.parse(event.eventType!)];
      if (eventType == null || packageName == null) continue;

      var appEvent = AppEvent.empty();
      appEvent.eventType = eventType;
      appEvent.time =
          DateTime.fromMillisecondsSinceEpoch(int.parse(event.timeStamp!));

      try {
        appEvent.appName = await _androidPackageManager.getApplicationLabel(
                packageName: packageName) ??
            packageName;
      } catch (e) {
        appEvent.appName = packageName;
      }

      try {
        appEvent.appIconByte = await _androidPackageManager.getApplicationIcon(
                packageName: packageName) ??
            defaultIcon;
      } catch (e) {
        appEvent.appIconByte = defaultIcon;
      }

      if (eventTypeForDurationList.contains(eventType)) {
        appNameToAppEventMap
            .putIfAbsent(appEvent.appName, () => List.empty(growable: true))
            .add(appEvent);
      }
    }

    appNameToAppEventMap.forEach((String appName, List<AppEvent> events) {
      for (int x = 0; x < events.length; x++) {
        var eventX = events[x];

        if (AppUtils.isResumed(eventX)) {
          int y = x + 1;

          while (y < events.length && !AppUtils.isPausedOrStopped(events[y])) {
            y++;
          }

          if (y < events.length) {
            var eventY = events[y];
            Duration duration = eventY.time.difference(eventX.time);
            int durationInSeconds = duration.inSeconds;

            if (durationInSeconds > 0) {
              String dateKey = AppUtils.formatDate(eventX.time);
              var appUsage = AppUsage(
                appName: appName,
                appIconByte: eventX.appIconByte,
                time: eventX.time,
                durationInSeconds: durationInSeconds,
              );
              appUsageByDate.putIfAbsent(dateKey, () => []).add(appUsage);
              x = y;
            }
          }
        }
      }
    });

    emit(state.copyWith(isLoading: false, appUsageByDate: appUsageByDate));

    final deviceInfo = await _deviceInfoPlugin.androidInfo;
    _deviceId = deviceInfo.id;
    await _sendDataToApi(appUsageByDate);
  }

  Future<void> _sendDataToApi(
      Map<String, List<AppUsage>> appUsageByDate) async {
    final url = Uri.parse('https://speed-byte.onrender.com/usage-data');
    List<Map<String, dynamic>> dataToSend =
        appUsageByDate.entries.expand((entry) {
      return entry.value.map((appUsage) {
        return {
          'app_name': appUsage.appName,
          'start_time': appUsage.time.toIso8601String(),
          'end_time': appUsage.time
              .add(Duration(seconds: appUsage.durationInSeconds))
              .toIso8601String(),
          'android_id': _deviceId,
        };
      });
    }).toList();

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'usageData': dataToSend}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        scaffoldStateKey.currentState?.showSnackBar(
            // const SnackBar(content: Text('App usage data sent successfully!')),
            const SnackBar(content: Text('Welcome')));
      } else {
        // scaffoldStateKey.currentState?.showSnackBar(
        //     // SnackBar(
        //     //     content: Text(
        //     //         'Failed to send data. Status: ${response.reasonPhrase} ${response.statusCode}')),

        //     );
      }
    } catch (e) {
      // scaffoldStateKey.currentState?.showSnackBar(
      //  SnackBar(content: Text('Error sending app usage data: $e')),
      // );
    }
  }
}
