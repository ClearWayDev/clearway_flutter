// auth_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;

final authStateProvider = StreamProvider<fb.User?>((ref) {
  return fb.FirebaseAuth.instance.authStateChanges();
});