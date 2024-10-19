import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_foreground_task/ui/with_foreground_task.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sms_reader/home/provider/home_function.dart';
import 'package:sms_reader/home/provider/home_provider.dart';
import 'package:sms_reader/main.dart';
import 'package:sms_reader/utils/request_function.dart';

class HomeView extends ConsumerStatefulWidget {
  const HomeView({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _HomeViewState();
}

class _HomeViewState extends ConsumerState<HomeView> {
  @override
  void initState() {
    initService();

    ref.read(loadingHomeProvider.notifier).state = true;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      prefs = await SharedPreferences.getInstance();
      if (prefs!.getString('token') == null) {
        ref.read(visibilityQrProvider.notifier).state = true;
        ref.read(visibilityConnectedProvider.notifier).state = false;
      } else {
        ref.read(visibilityQrProvider.notifier).state = false;
        ref.read(visibilityConnectedProvider.notifier).state = true;
      }

      ref.read(loadingHomeProvider.notifier).state = false;
      await requestPermissions();
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return WithForegroundTask(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('SMS tracker'),
        ),
        body: ref.watch(loadingHomeProvider) == true
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    height: 20,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Visibility(
                        visible: ref.watch(visibilityQrProvider),
                        child: GestureDetector(
                          onTap: () async {
                            await scanQR(
                              ref: ref,
                              context: context,
                            );
                          },
                          child: Container(
                            width: 200.0, // Set the width of the circle
                            height:
                                200.0, // Set the height of the circle (should match width for a perfect circle)
                            decoration: const BoxDecoration(
                              color:
                                  Colors.blue, // Background color of the circle
                              shape: BoxShape
                                  .circle, // Makes the container circular
                            ),
                            child: const Center(
                              child: Text(
                                'Scan QR code',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Visibility(
                    visible: ref.watch(visibilityConnectedProvider),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'You are connected',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                          ),
                        )
                      ],
                    ),
                  ),
                  const SizedBox(
                    height: 30,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Visibility(
                        visible: ref.watch(visibilityConnectedProvider),
                        child: GestureDetector(
                          onTap: () async {
                            ref
                                .read(visibilityConnectedProvider.notifier)
                                .state = false;
                            ref.read(visibilityQrProvider.notifier).state =
                                true;
                            // stopBackgroundService();
                            await stopService();
                            prefs!.remove('token');
                          },
                          child: Container(
                            width: 200.0, // Set the width of the circle
                            height:
                                200.0, // Set the height of the circle (should match width for a perfect circle)
                            decoration: const BoxDecoration(
                              color:
                                  Colors.red, // Background color of the circle
                              shape: BoxShape
                                  .circle, // Makes the container circular
                            ),
                            child: const Center(
                              child: Text(
                                'Stop',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }
}
