//fcm_token_notifier.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FcmTokenNotifier extends StateNotifier<String?> {
  FcmTokenNotifier() : super(null);

  void setToken(String token) {
    state = token;
  }

  void clearToken() {
    state = null;
  }
}

final fcmTokenProvider = StateNotifierProvider<FcmTokenNotifier, String?>(
  (ref) => FcmTokenNotifier(),
);
