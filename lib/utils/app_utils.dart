import 'package:flutter/services.dart';

import '../models/app_event.dart';

class AppUtils {
  static Future<Uint8List> loadIcon(String name) async {
    final ByteData data = await rootBundle.load('assets/$name');
    return data.buffer.asUint8List();
  }

  static bool isResumed(AppEvent appEvent) {
    return appEvent.eventType == "Activity Resumed";
  }

  static bool isPausedOrStopped(AppEvent appEvent) {
    return appEvent.eventType == "Activity Paused" ||
        appEvent.eventType == "Activity Stopped";
  }

  static String formatDate(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  static bool isAndroidPackageNamePresent(
      List<String> packages, String searchPackageName) {
    return packages.any(
      (element) {
        return element.toLowerCase().contains(searchPackageName.toLowerCase());
      },
    );
  }

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
}
