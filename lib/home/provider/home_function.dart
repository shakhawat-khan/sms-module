import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sms_reader/home/model/get_token_model.dart';
import 'package:sms_reader/home/model/info_model.dart';
import 'package:sms_reader/home/provider/home_provider.dart';
import 'package:sms_reader/main.dart';
import 'package:sms_reader/utils/app_url.dart';
import 'package:sms_reader/utils/log_messsage.dart';
import 'package:http/http.dart' as http;

Future<void> scanQR(
    {required WidgetRef ref, required BuildContext context}) async {
  String barcodeScanRes;
  // Platform messages may fail, so we use a try/catch PlatformException.
  try {
    barcodeScanRes = await FlutterBarcodeScanner.scanBarcode(
        '#ff6666', 'Cancel', true, ScanMode.QR);
    log(barcodeScanRes);
    ref.read(qrCodeResultProvider.notifier).state = barcodeScanRes;
    if (context.mounted) {
      await getToken(ref: ref, context: context);
    }
  } on PlatformException {
    barcodeScanRes = 'Failed to get platform version.';
  }

  // If the widget was removed from the tree while the asynchronous platform
  // message was in flight, we want to discard the reply rather than calling
  // setState to update our non-existent appearance.
}

Future<void> getToken(
    {required WidgetRef ref, required BuildContext context}) async {
  try {
    GetTokenModel tokenModel;

    final url = Uri.parse('$baseUrl/devices/connect');
    final response = await http.post(
      url,
      headers: {'vorosa-app-secret': 'xORrkbpiatLMTge8cunMoCl4oLgzyU2qbuxT'},
      body: {
        "appId": ref.read(qrCodeResultProvider),
        "name": ref.read(infoProvider)!.deviceName,
        "model": ref.read(infoProvider)!.deviceModel,
        "deviceId": ref.read(infoProvider)!.deviceId,
        "androidVerison": ref.read(infoProvider)!.androidVersion,
        "appVersion": ref.read(infoProvider)!.androidVersion,
        "buildNo": ref.read(infoProvider)!.buildNumber
      },
    );

    if (response.statusCode == 200) {
      tokenModel = GetTokenModel.fromJson(jsonDecode(response.body));

      ref.read(tokenProvider.notifier).state = tokenModel.data!.clientSecret!;

      logSmall(message: tokenModel.data!.clientSecret);

      ref.read(visibilityQrProvider.notifier).state = false;
      ref.read(visibilityConnectedProvider.notifier).state = true;
      ref.read(manualTokenButtonProvider.notifier).state = false;
      ref.read(manualTokenTextProvider.notifier).state = false;
      // await initializeService();
      await startService();
      await prefs!.setString(
        'token',
        tokenModel.data!.clientSecret!,
      );
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Your QR is not valid. Please try it again',
            ),
          ),
        );
      }
    }
  } catch (e) {
    logSmall(message: 'the error is $e');
  }
}

// The callback function should always be a top-level function.
@pragma('vm:entry-point')
void startCallback() {
  // The setTaskHandler function must be called to handle the task in the background.
  FlutterForegroundTask.setTaskHandler(MyTaskHandler());
}

class MyTaskHandler extends TaskHandler {
  static const String incrementCountCommand = 'incrementCount';
  DateTime nowDateTime = DateTime.now();
  List<Map<String, dynamic>> dataList = [];

  void callApi() async {
    prefs = await SharedPreferences.getInstance();
    // Update notification content.
    String? token = prefs!.getString('token');
    PermissionStatus permission = await Permission.sms.status;

    final SmsQuery query = SmsQuery();

    if (permission.isGranted) {
      Future<List<SmsMessage>> filterMessagesFromDate(DateTime fromDate) async {
        final messages = await query.querySms(
          kinds: [SmsQueryKind.inbox],
        );

        // Filter messages based on the provided date
        List<SmsMessage> filteredMessages = messages.where((message) {
          return message.date!.isAfter(fromDate);
        }).toList();

        return filteredMessages;
      }

      // void getMessages() async {
      //   // Example: filter from yesterday
      //   List<SmsMessage> recentMessages =
      //       await filterMessagesFromDate(nowDateTime);

      //   // Print the filtered messages
      //   for (var message in recentMessages) {
      //     if (nowDateTime.isBefore(message.date!)) {
      //       dataList.add({"from": message.address, "message": message.body});

      //       nowDateTime = message.date!;
      //     }
      //   }
      //   logSmall(message: 'message');

      //   final messageSendPayload = {
      //     "deviceId": "DEVICE-1234567892",
      //     "messages": dataList
      //   };

      //   if (dataList.isNotEmpty) {
      //     try {
      //       final url =
      //           Uri.parse('http://20.6.93.121:4700/api/v1/messages/sent');
      //       final response = await http
      //           .post(url, body: jsonEncode(messageSendPayload), headers: {
      //         "Content-Type": "application/json", // Ensure you're sending JSON
      //         'access_token': token ?? '',
      //         'vorosa-app-secret': 'xORrkbpiatLMTge8cunMoCl4oLgzyU2qbuxT',
      //         'vorosa-client-secret': 'xORrkbpiatLMTge8cunMoCl4oLgzyU2qbuxT',
      //       });

      //       logSmall(message: response.body);

      //       if (response.statusCode == 200 || response.statusCode == 201) {
      //         log(response.body);

      //         dataList.clear();
      //       } else {
      //         logSmall(message: 'gg');
      //       }
      //     } catch (e) {
      //       logMessage(title: 'error from sending message', message: e);
      //     }
      //   }
      // }

      void getMessages() async {
        // Example: filter from yesterday
        List<SmsMessage> recentMessages =
            await filterMessagesFromDate(nowDateTime);

        // Print the filtered messages
        for (var message in recentMessages) {
          if (nowDateTime.isBefore(message.date!)) {
            dataList.add({"from": message.address, "message": message.body});
            nowDateTime = message.date!;
          }
        }

        logSmall(message: 'message');

        // final messageSendPayload = {
        //   "deviceId": "DEVICE-1234567892",
        //   "messages": dataList
        // };

        final postData = {
          "deviceId": "DEVICE-1234567892",
          "messages": [
            {
              "from": "bkash",
              "body":
                  "You have received payment Tk 14.00 from 01717541865. Ref 12356. Fee Tk 0.00. Balance Tk 14.00. TrxID BIJ1PGUED3 at 19/09/2024 15:02",
              "deviceSim": "Airtel-1"
            }
          ]
        };

        if (dataList.isNotEmpty) {
          try {
            final url =
                Uri.parse('http://20.6.93.121:4700/api/v1/messages/sent');

            // Here we use jsonEncode to convert the messageSendPayload to JSON
            final response = await http.post(
              url,
              body: jsonEncode(postData), // JSON-encoded body
              headers: {
                'vorosa-app-secret': 'xORrkbpiatLMTge8cunMoCl4oLgzyU2qbuxT',
                'vorosa-client-secret': 'xORrkbpiatLMTge8cunMoCl4oLgzyU2qbuxT',
              },
            );

            logSmall(message: response.body);

            if (response.statusCode == 200 || response.statusCode == 201) {
              log(response.body);
              dataList.clear();
            } else {
              logSmall(
                  message: 'Failed with status code: ${response.statusCode}');
            }
          } catch (e) {
            logMessage(
                title: 'Error from sending message', message: e.toString());
          }
        }
      }

      getMessages();
    } else {
      await Permission.sms.request();
    }

    FlutterForegroundTask.updateService(
      notificationTitle: 'SMS Service',
      notificationText: 'SMS service is running',
    );

    // Send data to main isolate.
    FlutterForegroundTask.sendDataToMain('hello world');
  }

  // Called when the task is started.
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    print('onStart(starter: ${starter.name})');
    callApi();
  }

  // Called by eventAction in [ForegroundTaskOptions].
  // - nothing() : Not use onRepeatEvent callback.
  // - once() : Call onRepeatEvent only once.
  // - repeat(interval) : Call onRepeatEvent at milliseconds interval.
  @override
  void onRepeatEvent(DateTime timestamp) {
    callApi();
  }

  // Called when the task is destroyed.
  @override
  Future<void> onDestroy(DateTime timestamp) async {
    print('onDestroy');
  }

  // Called when data is sent using [FlutterForegroundTask.sendDataToTask].
  @override
  void onReceiveData(Object data) {
    print('onReceiveData: $data');
    if (data == incrementCountCommand) {
      callApi();
    }
  }

  // Called when the notification button is pressed.
  @override
  void onNotificationButtonPressed(String id) {
    print('onNotificationButtonPressed: $id');
  }

  // Called when the notification itself is pressed.
  //
  // AOS: "android.permission.SYSTEM_ALERT_WINDOW" permission must be granted
  // for this function to be called.
  @override
  void onNotificationPressed() {
    FlutterForegroundTask.launchApp('/');
    print('onNotificationPressed');
  }

  // Called when the notification itself is dismissed.
  //
  // AOS: only work Android 14+
  // iOS: only work iOS 10+
  @override
  void onNotificationDismissed() {
    print('onNotificationDismissed');
  }
}

void initService() {
  FlutterForegroundTask.init(
    androidNotificationOptions: AndroidNotificationOptions(
      channelId: 'foreground_service',
      channelName: 'Foreground Service Notification',
      channelDescription:
          'This notification appears when the foreground service is running.',
      channelImportance: NotificationChannelImportance.LOW,
      priority: NotificationPriority.LOW,
    ),
    iosNotificationOptions: const IOSNotificationOptions(
      showNotification: false,
      playSound: false,
    ),
    foregroundTaskOptions: ForegroundTaskOptions(
      eventAction: ForegroundTaskEventAction.repeat(5000),
      autoRunOnBoot: true,
      autoRunOnMyPackageReplaced: true,
      allowWakeLock: true,
      allowWifiLock: true,
    ),
  );
}

Future<ServiceRequestResult> startService() async {
  if (await FlutterForegroundTask.isRunningService) {
    return FlutterForegroundTask.restartService();
  } else {
    return FlutterForegroundTask.startService(
      serviceId: 256,
      notificationTitle: 'Foreground Service is running',
      notificationText: 'Tap to return to the app',
      notificationIcon: null,
      notificationButtons: [
        const NotificationButton(id: 'btn_hello', text: 'hello'),
      ],
      callback: startCallback,
    );
  }
}

Future<ServiceRequestResult> stopService() async {
  return FlutterForegroundTask.stopService();
}

Future<Info?> getDeviceInfo({required WidgetRef ref}) async {
  DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
  PackageInfo packageInfo = await PackageInfo.fromPlatform();

  if (Platform.isAndroid) {
    // For Android
    AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;

    ref.read(infoProvider.notifier).state = Info(
      deviceName: androidInfo.device,
      deviceModel: androidInfo.model,
      deviceId: androidInfo.id,
      androidVersion: androidInfo.version.release,
      appVersion: packageInfo.version,
      buildNumber: packageInfo.buildNumber,
    );

    return Info(
      deviceName: androidInfo.device,
      deviceModel: androidInfo.model,
      deviceId: androidInfo.id,
      androidVersion: androidInfo.version.release,
      appVersion: packageInfo.version,
      buildNumber: packageInfo.buildNumber,
    );
  }
  return null;
  // else if (Platform.isIOS) {
  //   // For iOS
  //   IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
  //   setState(() {
  //     deviceName = iosInfo.name ?? 'Unknown';
  //     deviceModel = iosInfo.model ?? 'Unknown';
  //     deviceId = iosInfo.identifierForVendor ?? 'Unknown';
  //     androidVersion = iosInfo.systemVersion ?? 'Unknown';
  //   });
  // }

  // Get app version and build number
}
