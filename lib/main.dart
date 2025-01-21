import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';
import 'package:workmanager/workmanager.dart';

import 'modules/home/blocs/app_usage_cubit/app_usage_cubit.dart';
import 'modules/home/screens/app_usage_screen.dart';

final GlobalKey<ScaffoldMessengerState> scaffoldStateKey =
    GlobalKey<ScaffoldMessengerState>();

const periodicTaskName = "com.example.speedbyte.pushdatatoservertask";

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask(
    (taskName, inputData) async {
      try {
        switch (taskName) {
          case periodicTaskName:
            var deviceId = DeviceInfoPlugin();
            final data = await deviceId.androidInfo;
            print(data.id);
            return true;
          default:
        }
      } catch (err) {
        Logger().e(err.toString());
        throw Exception(err);
      }

      return Future.value(true);
    },
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Workmanager().initialize(callbackDispatcher, isInDebugMode: true);
  Workmanager().registerPeriodicTask(
    periodicTaskName,
    periodicTaskName,
    constraints: Constraints(
      networkType: NetworkType.connected,
    ),
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
