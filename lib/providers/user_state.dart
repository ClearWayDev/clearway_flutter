// user_notifier.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';

class UserState extends StateNotifier<User?> {
  UserState()
    : super(
        User(accountType: UserType.blind, email: "sfdf", uid: "fdfdfd"),
      ); // null means no user logged in

  void setUser(User user) => state = user;

  void updateUID(String newUID) {
    if (state != null) {
      state = state!.copyWith(uid: newUID);
    }
  }

  void logout() => state = null;
}

final userProvider = StateNotifierProvider<UserState, User?>((ref) {
  return UserState();
});
