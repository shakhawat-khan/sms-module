import 'package:flutter_riverpod/flutter_riverpod.dart';

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
