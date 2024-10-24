import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sms_reader/home/model/info_model.dart';

final tokenProvider = StateProvider<String?>((ref) {
  return null;
});

final qrCodeResultProvider = StateProvider<String?>((ref) {
  return null;
});

final visibilityQrProvider = StateProvider<bool>((ref) {
  return true;
});

final visibilityConnectedProvider = StateProvider<bool>((ref) {
  return false;
});

final loadingHomeProvider = StateProvider<bool>((ref) {
  return true;
});

final manualTokenButtonProvider = StateProvider<bool>((ref) {
  return true;
});

final manualTokenTextProvider = StateProvider<bool>((ref) {
  return false;
});

// Step 1: Create a family provider for TextEditingController
final textControllerProvider = Provider.family
    .autoDispose<TextEditingController, String>((ref, fieldName) {
  final controller = TextEditingController();
  ref.onDispose(() {
    controller.dispose(); // Make sure to dispose of the controller
  });
  return controller;
});

final infoProvider = StateProvider<Info?>((ref) {
  return;
});
