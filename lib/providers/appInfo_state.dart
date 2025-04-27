// user_notifier.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/appInfo.dart';

class AppInfoState extends StateNotifier<AppInfo?> {
  AppInfoState() : super(AppInfo(backendUrl: 'http://localhost:3000'));

  void setInfo(AppInfo appInfo) => state = appInfo;

  void updateURL(String url) {
    state = state!.copyWith(backendUrl: url);
  }
}

final appInfoProvider = StateNotifierProvider<AppInfoState, AppInfo?>((ref) {
  return AppInfoState();
});
