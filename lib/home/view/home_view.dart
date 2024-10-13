import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sms_reader/home/provider/home_function.dart';
import 'package:sms_reader/home/provider/home_provider.dart';
import 'package:sms_reader/utils/log_messsage.dart';

class Home extends ConsumerWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SMS tracker'),
      ),
      body: Column(
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
                      color: Colors.blue, // Background color of the circle
                      shape: BoxShape.circle, // Makes the container circular
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
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Visibility(
                visible: ref.watch(visibilityConnectedProvider),
                child: GestureDetector(
                  onTap: () async {
                    // await scanQR(ref: ref);
                  },
                  child: Container(
                    width: 200.0, // Set the width of the circle
                    height:
                        200.0, // Set the height of the circle (should match width for a perfect circle)
                    decoration: const BoxDecoration(
                      color: Colors.green, // Background color of the circle
                      shape: BoxShape.circle, // Makes the container circular
                    ),
                    child: const Center(
                      child: Text(
                        'Connected',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          ElevatedButton(
            onPressed: () async {
              final SmsQuery query = SmsQuery();
              // List<SmsMessage> messages = [];
              var permission = await Permission.sms.status;
              log(permission.isGranted.toString());
              if (permission.isGranted) {
                final messages = await query.querySms(
                  kinds: [
                    SmsQueryKind.inbox,
                  ],
                  // address: '+254712345789',
                  // count: 10,
                );

                for (int i = 0; i < messages.length; i++) {
                  logSmall(message: messages[i].body);
                }
                debugPrint('sms inbox messages: ${messages.length}');
              } else {
                await Permission.sms.request();
              }
            },
            child: const Text(
              'press',
            ),
          ),
        ],
      ),
    );
  }
}
