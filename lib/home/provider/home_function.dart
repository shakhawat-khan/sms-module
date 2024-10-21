import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sms_reader/home/model/get_token_model.dart';
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

    final url =
        Uri.parse('${baseUrl}login?token=${ref.read(qrCodeResultProvider)}');
    final response = await http.post(url);

    logMessage(
        title: '${baseUrl}login?token=${ref.read(qrCodeResultProvider)}',
        message: response.body);

    if (response.statusCode == 200) {
      tokenModel = GetTokenModel.fromJson(jsonDecode(response.body));

      ref.read(tokenProvider.notifier).state = tokenModel.accessToken;

      logSmall(message: tokenModel.accessToken);

      ref.read(visibilityQrProvider.notifier).state = false;
      ref.read(visibilityConnectedProvider.notifier).state = true;
      // await initializeService();
      await startService();
      await prefs!.setString('token', tokenModel.accessToken!);
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
        if (dataList.isNotEmpty) {
          try {
            final url = Uri.parse('https://test.yupsis.com/api/v1/webhooks');
            final response =
                await http.post(url, body: jsonEncode(dataList), headers: {
              "Content-Type": "application/json", // Ensure you're sending JSON
              'access_token': token ?? ''
            });

            if (response.statusCode == 200 || response.statusCode == 201) {
              log(response.body);

              dataList.clear();
            } else {
              logSmall(message: 'gg');
            }
          } catch (e) {
            logMessage(title: 'error from sending message', message: e);
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
