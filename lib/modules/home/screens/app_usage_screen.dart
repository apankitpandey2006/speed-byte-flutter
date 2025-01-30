import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../models/app_usage.dart';
import '../blocs/app_usage_cubit/app_usage_cubit.dart';

class AppUsageScreen extends StatefulWidget {
  const AppUsageScreen({super.key});

  @override
  State<AppUsageScreen> createState() => _AppUsageScreenState();
}

class _AppUsageScreenState extends State<AppUsageScreen> {
  @override
  void initState() {
    super.initState();
    context.read<AppUsageCubit>()
      ..checkPermission()
      // ..sendDeviceInfoToApi()
      ..getAllAppUsageInfo();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<AppUsageCubit, AppUsageState>(
        listener: (context, state) {},
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          return RefreshIndicator(
            onRefresh: () => context.read<AppUsageCubit>().getAllAppUsageInfo(),
            child: ListView(
              children: state.appUsageByDate.entries
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
                        // Text(

                        //   date,
                        //   style: const TextStyle(
                        //       fontSize: 20, fontWeight: FontWeight.bold),
                        // ),
                        // const SizedBox(height: 8),
                        // ...usages.map((appUsage) {
                        //   return ListTile(
                        //     leading: appUsage.appIconByte != null
                        //         ? Image.memory(
                        //             appUsage.appIconByte!,
                        //             width: 40,
                        //             height: 40,
                        //           )
                        //         : const Icon(Icons.apps),
                        //     title: Text(appUsage.appName),
                        //     subtitle: Column(
                        //       crossAxisAlignment: CrossAxisAlignment.start,
                        //       children: [
                        //         Text(
                        //             "Start Time: ${appUsage.time.toString().substring(0, 19)}"),
                        //         Text(
                        //             "End Time: ${appUsage.time.add(Duration(seconds: appUsage.durationInSeconds)).toString().substring(0, 19)}"),
                        //         Text("Duration: ${appUsage.durationInText}"),
                        //       ],
                        //     ),
                        //   );
                        // }),
                        Text("Welcome to Speed AV")
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          );
        },
      ),
    );
  }
}
