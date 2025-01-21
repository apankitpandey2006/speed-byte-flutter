import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:usage_stats/usage_stats.dart';
import 'package:android_package_manager/android_package_manager.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:async';
import 'models/app_event.dart';
import 'models/app_model.dart';
import 'models/app_usage.dart';
import 'utils.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, List<AppUsage>> _appUsageByDate = {};
  final AndroidPackageManager _packageManager = AndroidPackageManager();
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();

  final List<String> _trackedPackages = [
    'com.example.alphabet_app',
    'com.example.varnmala_app',
    'com.DivineLab.Alphabet_BlackWhite',
    'com.DivineLab.Varnamala'
  ];

  String _deviceId = 'Unknown';
  String _deviceName = 'Unknown';
  final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();

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

  Timer? _schedulerTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshIndicatorKey.currentState?.show();
    });
    _initializeDeviceInfo();
    _startScheduler();
  }

  @override
  void dispose() {
    _schedulerTimer?.cancel();
    super.dispose();
  }

  Future<void> _initializeDeviceInfo() async {
    try {
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      setState(() {
        _deviceId = androidInfo.id;
        _deviceName = androidInfo.model;
      });
    } on PlatformException {
      setState(() {
        _deviceId = 'Failed to get device ID';
        _deviceName = 'Failed to get device name';
      });
    }
  }

  void _startScheduler() {
    _schedulerTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _sendDeviceInfoToApi();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Speed"),
        actions: [
          IconButton(
            onPressed: _sendDataToApi,
            icon: const Icon(Icons.upload),
            tooltip: 'Send Usage Data to API',
          ),
          IconButton(
            onPressed: _sendDeviceInfoToApi,
            icon: const Icon(Icons.info),
            tooltip: 'Send Device Info to API',
          ),
        ],
      ),
      body: RefreshIndicator(
        key: _refreshIndicatorKey,
        onRefresh: _updateData,
        child: _appUsageByDate.isEmpty
            ? const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'No data found for the selected apps.',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
              )
            : ListView(
                children: _appUsageByDate.entries
                    .toList()
                    .map((entry) => MapEntry(entry.key, entry.value))
                    .toList()
                    .reversed
                    .map((entry) {
                  String date = entry.key;
                  List<AppUsage> usages = entry.value;
                  return Card(
                    margin:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            date,
                            style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          ...usages.map((appUsage) {
                            return ListTile(
                              leading: appUsage.appIconByte != null
                                  ? Image.memory(
                                      appUsage.appIconByte!,
                                      width: 40,
                                      height: 40,
                                    )
                                  : const Icon(Icons.apps),
                              title: Text(appUsage.appName),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                      "Start Time: ${appUsage.time.toString().substring(0, 19)}"),
                                  Text(
                                      "End Time: ${appUsage.time.add(Duration(seconds: appUsage.durationInSeconds)).toString().substring(0, 19)}"),
                                  Text("Duration: ${appUsage.durationInText}"),
                                ],
                              ),
                            );
                          }).toList(),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
      ),
    );
  }

  Future<void> _updateData() async {
    UsageStats.grantUsagePermission();

    setState(() {
      _appUsageByDate.clear();
    });

    DateTime endDate = DateTime.now();
    DateTime startDate = endDate.subtract(const Duration(days: 1));

    List<EventUsageInfo> queryEvents =
        await UsageStats.queryEvents(startDate, endDate);

    Map<String, List<AppEvent>> appNameToAppEventMap = {};
    Map<String, List<AppUsage>> appUsageByDate = {};

    var defaultIcon = await _loadIcon("default-icon.png");

    for (var event in queryEvents) {
      var packageName = event.packageName;
      if (!_trackedPackages.contains(packageName)) continue;

      var eventType = eventTypeMap[int.parse(event.eventType!)];
      if (eventType == null || packageName == null) continue;

      var appEvent = AppEvent.empty();
      appEvent.eventType = eventType;
      appEvent.time =
          DateTime.fromMillisecondsSinceEpoch(int.parse(event.timeStamp!));

      try {
        appEvent.appName = await _packageManager.getApplicationLabel(
                packageName: packageName) ??
            packageName;
      } catch (e) {
        appEvent.appName = packageName;
      }

      try {
        appEvent.appIconByte = await _packageManager.getApplicationIcon(
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

        if (_isResumed(eventX)) {
          int y = x + 1;

          while (y < events.length && !_isPausedOrStopped(events[y])) {
            y++;
          }

          if (y < events.length) {
            var eventY = events[y];
            Duration duration = eventY.time.difference(eventX.time);
            int durationInSeconds = duration.inSeconds;

            if (durationInSeconds > 0) {
              String dateKey = _formatDate(eventX.time);
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

    setState(() {
      _appUsageByDate = appUsageByDate;
    });
  }

  Future<void> _sendDataToApi() async {
    final url = Uri.parse('http://10.0.2.2:3000/usage-data');
    List<Map<String, dynamic>> dataToSend =
        _appUsageByDate.entries.expand((entry) {
      String date = entry.key;
      return entry.value.map((appUsage) {
        return {
          'app_name': appUsage.appName,
          'start_time': appUsage.time.toIso8601String(), // Use local time
          'end_time': appUsage.time
              .add(Duration(seconds: appUsage.durationInSeconds))
              .toIso8601String(), // Use local time
          'android_id': _deviceId,
        };
      });
    }).toList();

    try {
      debugPrint('Data to send: $dataToSend');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'usageData': dataToSend}),
      );
      debugPrint('Response: ${response.body}');
      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data successfully sent to API.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Failed to send data. Status: ${response.reasonPhrase} ${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending data: $e')),
      );
    }
  }

  Future<void> _sendDeviceInfoToApi() async {
    final url = Uri.parse('https://speed-byte.onrender.com/devices');
    final dataToSend = {
      'device_name': _deviceName,
      'android_id': _deviceId,
    };

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(dataToSend),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Device info successfully sent to API.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Failed to send device info. Status: ${response.reasonPhrase} ${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending device info: $e')),
      );
    }
  }

  bool _isResumed(AppEvent appEvent) {
    return appEvent.eventType == "Activity Resumed";
  }

  bool _isPausedOrStopped(AppEvent appEvent) {
    return appEvent.eventType == "Activity Paused" ||
        appEvent.eventType == "Activity Stopped";
  }

  String _formatDate(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  Future<Uint8List> _loadIcon(String name) async {
    final ByteData data = await rootBundle.load('assets/$name');
    return data.buffer.asUint8List();
  }
}
