// user_notifier.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';

class UserState extends StateNotifier<User?> {
  UserState() : super(null); // null means no user logged in

  void setUser(User user) => state = user;

  void updateName(String newName) {
    if (state != null) {
      state = state!.copyWith(name: newName);
    }
  }

  void logout() => state = null;
}

final userProvider = StateNotifierProvider<UserState, User?>((ref) {
  return UserState();
});
