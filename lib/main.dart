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
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

final GlobalKey<ScaffoldMessengerState> scaffoldStateKey =
    GlobalKey<ScaffoldMessengerState>();
late DeviceInfoPlugin _deviceInfoPlugin;

const periodicTaskName = "com.example.speedbyte.pushdatatoservertask";
const storage = FlutterSecureStorage();

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

            final uniqueUuid =
                await getOrCreateDeviceId(); // Fetch the unique UUID

            // Fetch the current location
            final position = await _determinePosition();
            final latitude = position?.latitude ?? 0.0;
            final longitude = position?.longitude ?? 0.0;

            final usageData = appUsageByDate.entries.expand((entry) {
              return entry.value.map((appUsage) {
                return {
                  'app_name': appUsage.appName,
                  'start_time': appUsage.time.toIso8601String(),
                  'end_time': appUsage.time
                      .add(Duration(seconds: appUsage.durationInSeconds))
                      .toIso8601String(),
                  'android_id': androidId,
                  'unique_uuid': uniqueUuid,
                  'latitude': latitude, // Attach latitude
                  'longitude': longitude, // Attach longitude
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

Future<Position?> _determinePosition() async {
  bool serviceEnabled;
  LocationPermission permission;

  // Check if location services are enabled
  serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    print("Location services are disabled.");
    return null;
  }
  // Check for permissions
  permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      print("Location permissions are denied.");
      return null;
    }
  }

  if (permission == LocationPermission.deniedForever) {
    print("Location permissions are permanently denied.");
    return null;
  }

  return await Geolocator.getCurrentPosition();
}

Future<String> getOrCreateDeviceId() async {
  String? deviceId = await storage.read(key: "device_id");

  if (deviceId == null) {
    final deviceInfo = DeviceInfoPlugin();
    final androidInfo = await deviceInfo.androidInfo;
    final androidId = androidInfo.id;
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    deviceId = "${androidId}_$timestamp";
    await storage.write(key: "device_id", value: deviceId);
  }

  return deviceId;
}

Future<void> handleLocationPermission() async {
  // Check the current status of location permission
  var status = await Permission.location.request();

  if (status.isGranted) {
    // Logic when permission is granted
    print("Location permission granted.");
    // You can start fetching the user's location here
    _determinePosition();
  } else if (status.isDenied) {
    // Logic when permission is denied
    print("Location permission denied.");
    // You might want to show a dialog or notification to the user
  } else if (status.isPermanentlyDenied) {
    // Logic when permission is permanently denied
    print("Location permission is permanently denied.");
    // Open app settings so the user can manually grant permission
    await openAppSettings();
  } else if (status.isRestricted) {
    // Logic for restricted permissions (e.g., parental controls)
    print("Location permission is restricted.");
    // Show a message explaining restricted permissions
  }
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
  print('usageData $usageData');
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

Future<void> sendDeviceInfoToApi() async {
  final deviceInfo = await _deviceInfoPlugin.androidInfo;
  String fetchedDeviceId = await getOrCreateDeviceId();

  final url = Uri.parse('https://speed-byte.onrender.com/devices');
  final dataToSend = {
    'device_name': deviceInfo.model,
    'android_id': deviceInfo.id,
    'unique_uuid': fetchedDeviceId,
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
    Permission.location.request();
    _fetchData();
    sendDeviceInfoToApi();
  }

  Future<void> _fetchData() async {
    String? deviceId;
    Position? position;
    String fetchedDeviceId = await getOrCreateDeviceId();
    Position? fetchedPosition = await _determinePosition();
    Stream<Position>? positionStream;

    positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Update when the device moves 10 meters
      ),
    );

    positionStream?.listen((Position newPosition) {
      setState(() {
        position = newPosition;
      });
      print(
          "🔄 Updated Location: ${position?.latitude}, ${position?.longitude}");
    });

    setState(() {
      deviceId = fetchedDeviceId;
      position = fetchedPosition;
    });

    print("Device ID: $deviceId");
    print("Latitude: ${position?.latitude}, Longitude: ${position?.longitude}");
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
