// user_info.dart
import 'package:clearway/models/user.dart';

class UserInfo {
  final String uid;
  final String username;
  final UserType userType;
  final String fcmToken;

  UserInfo({required this.uid,required this.username, required this.userType, required this.fcmToken});

  UserInfo copyWith({String? uid, UserType? userType, String? fcmToken}) {
    return UserInfo(
      uid: uid ?? this.uid,
      username: username ?? this.username,
      userType: userType ?? this.userType,
      fcmToken: fcmToken ?? this.fcmToken,
    );
  }
}