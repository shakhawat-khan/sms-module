import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sms_reader/home/model/get_token_model.dart';
import 'package:sms_reader/home/provider/home_provider.dart';
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
