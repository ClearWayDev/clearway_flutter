import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  final String uid;
  final String email;
  final UserType accountType;

  User({required this.uid, required this.email, required this.accountType});

  // Convert a User object to a Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'accountType': accountType.toString().split('.').last, // Store as string
    };
  }

  // Create a User object from a Firestore DocumentSnapshot
  factory User.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return User(
      uid: data['uid'] ?? '',
      email: data['email'] ?? '',
      accountType: _accountTypeFromString(data['accountType']),
    );
  }

  // Convert the string back to UserType
  static UserType _accountTypeFromString(String accountTypeStr) {
    switch (accountTypeStr) {
      case 'blind':
        return UserType.blind;
      case 'volunteer':
        return UserType.volunteer;
      default:
        throw ArgumentError('Unknown accountType: $accountTypeStr');
    }
  }

  User copyWith({String? uid, String? email, UserType? accountType}) {
    return User(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      accountType: accountType ?? this.accountType,
    );
  }
}

enum UserType { blind, volunteer }
