import 'package:android_package_manager/android_package_manager.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:usage_stats/usage_stats.dart';
import 'package:workmanager/workmanager.dart' as workmanager;
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'models/app_event.dart';
import 'models/app_usage.dart';
import 'modules/home/blocs/app_usage_cubit/app_usage_cubit.dart';
import 'modules/home/screens/app_usage_screen.dart';
import 'utils/app_utils.dart';

final GlobalKey<ScaffoldMessengerState> scaffoldStateKey =
    GlobalKey<ScaffoldMessengerState>();

const periodicTaskName = "com.example.speedbyte.pushdatatoservertask";

@pragma('vm:entry-point')
void callbackDispatcher() {
  workmanager.Workmanager().executeTask(
    (taskName, inputData) async {
      try {
        switch (taskName) {
          case periodicTaskName || 'simpleTask':
            WidgetsFlutterBinding.ensureInitialized();

            // Initialize necessary plugins
            final deviceInfoPlugin = DeviceInfoPlugin();

            // Fetch device information
            final androidInfo = await deviceInfoPlugin.androidInfo;
            final androidId = androidInfo.id;

            // Prepare the data
            final appUsageByDate = await getData();
            final usageData = appUsageByDate.entries.expand((entry) {
              return entry.value.map((appUsage) {
                return {
                  'app_name': appUsage.appName,
                  'start_time': appUsage.time.toIso8601String(),
                  'end_time': appUsage.time
                      .add(Duration(seconds: appUsage.durationInSeconds))
                      .toIso8601String(),
                  'android_id': androidId,
                };
              });
            }).toList();
            // Send data to the API
            final isSuccess = await sendDataToApi(usageData);
            return true;
          default:
            print('Unhandled task: $taskName');
            return false;
        }
      } catch (err) {
        print('Error in background task: $err');
        return false;
      }
    },
  );
}

Future<Map<String, List<AppUsage>>> getData() async {
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

  final List<String> trackedPackages = [
    'com.example.alphabet_app',
    'com.example.varnmala_app',
    'com.DivineLab.Alphabet_BlackWhite',
    'com.DivineLab.Varnamala',
  ];
  final startDate = DateTime.now().subtract(const Duration(days: 1));
  final endDate = DateTime.now();

  List<EventUsageInfo> queryEvents =
      await UsageStats.queryEvents(startDate, endDate);

  final AndroidPackageManager androidPackageManager = AndroidPackageManager();

  Map<String, List<AppEvent>> appNameToAppEventMap = {};
  Map<String, List<AppUsage>> appUsageByDate = {};

  var defaultIcon = await AppUtils.loadIcon("default-icon.png");

  for (var event in queryEvents) {
    var packageName = event.packageName;
    if (!AppUtils.isAndroidPackageNamePresent(
        trackedPackages, packageName ?? "")) {
      continue;
    }

    var eventType = eventTypeMap[int.parse(event.eventType!)];
    if (eventType == null || packageName == null) continue;

    var appEvent = AppEvent.empty();
    appEvent.eventType = eventType;
    appEvent.time =
        DateTime.fromMillisecondsSinceEpoch(int.parse(event.timeStamp!));

    try {
      appEvent.appName = await androidPackageManager.getApplicationLabel(
              packageName: packageName) ??
          packageName;
    } catch (e) {
      appEvent.appName = packageName;
    }

    try {
      appEvent.appIconByte = await androidPackageManager.getApplicationIcon(
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

  return appUsageByDate;
}

Future<bool> sendDataToApi(List<Map<String, dynamic>> usageData) async {
  const apiUrl = 'https://speed-byte.onrender.com/usage-data';
  const maxRetries = 3;
  for (int attempt = 0; attempt < maxRetries; attempt++) {
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'usageData': usageData}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        Logger().i('Data successfully sent to API.');
        return true;
      } else {
        Logger().w(
            'Attempt $attempt: Failed to send data. Status: ${response.statusCode}');
      }
    } catch (err) {
      Logger().e('Attempt $attempt: Error sending data', error: err);
    }
  }

  Logger().e('Failed to send data after $maxRetries attempts.');
  return false;
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize WorkManager
  workmanager.Workmanager().initialize(callbackDispatcher, isInDebugMode: true);

  workmanager.Workmanager().registerOneOffTask(
    'simpleTask',
    'simpleTask',
    initialDelay: const Duration(minutes: 2),
    existingWorkPolicy: workmanager.ExistingWorkPolicy.replace,
    backoffPolicy: workmanager.BackoffPolicy.linear,
  );

  // Register periodic task
  workmanager.Workmanager().registerPeriodicTask(
    periodicTaskName, // Task name
    periodicTaskName, // Unique task identifier
    frequency:
        const Duration(minutes: 15), // Minimum allowed interval is 15 minutes
    constraints: workmanager.Constraints(
      networkType:
          workmanager.NetworkType.connected, // Ensure the device is online
    ),
    existingWorkPolicy: workmanager.ExistingWorkPolicy.replace,
    backoffPolicy: workmanager.BackoffPolicy.linear,
  );

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    Permission.notification.request(); // FIXME: Remove this line
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => AppUsageCubit(),
        ),
      ],
      child: MaterialApp(
        scaffoldMessengerKey: scaffoldStateKey,
        debugShowCheckedModeBanner: false,
        home: AppUsageScreen(),
      ),
    );
  }
}
