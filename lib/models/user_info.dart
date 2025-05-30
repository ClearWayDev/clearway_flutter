// user_info.dart
import 'package:clearway/models/user.dart';

class UserInfo {
  final String uid;
  final UserType userType;
  final String fcmToken;

  UserInfo({required this.uid, required this.userType, required this.fcmToken});

  UserInfo copyWith({String? uid, UserType? userType, String? fcmToken}) {
    return UserInfo(
      uid: uid ?? this.uid,
      userType: userType ?? this.userType,
      fcmToken: fcmToken ?? this.fcmToken,
    );
  }
}
