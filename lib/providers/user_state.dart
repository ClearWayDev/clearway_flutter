// user_notifier.dart
import 'package:clearway/models/user_info.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:clearway/models/user.dart';

class UserState extends StateNotifier<UserInfo?> {
  UserState()
    : super(
        UserInfo(userType: UserType.blind, fcmToken: "sfdf", uid: "fdfdfd", username: "fdfdfd"),
      ); // null means no user logged in

  void setUser(UserInfo user) => state = user;

  void updateUID(String newUID) {
    if (state != null) {
      state = state!.copyWith(uid: newUID);
    }
  }

  void logout() => state = null;
}

final userProvider = StateNotifierProvider<UserState, UserInfo?>((ref) {
  return UserState();
});
