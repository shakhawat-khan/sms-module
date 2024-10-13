import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';

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
