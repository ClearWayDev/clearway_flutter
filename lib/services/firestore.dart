import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/user.dart' as localUser; // Your User class file

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<localUser.User?> getUserByUid(String uid) async {
    try {
      DocumentSnapshot<Map<String, dynamic>> docSnapshot =
          await _db.collection('users').doc(uid).get();
      if (docSnapshot.exists) {
        return localUser.User.fromFirestore(
          docSnapshot,
        ); // Assumes your `User.fromFirestore` method
      } else {
        return null; // User not found
      }
    } catch (e) {
      debugPrint("Error getting user by UID: $e");
      return null;
    }
  }

  Future<localUser.User?> getUserByEmail(String email) async {
    try {
      QuerySnapshot<Map<String, dynamic>> querySnapshot =
          await _db
              .collection('users')
              .where('email', isEqualTo: email)
              .limit(1) // Ensure we only get one document
              .get();

      if (querySnapshot.docs.isNotEmpty) {
        DocumentSnapshot<Map<String, dynamic>> docSnapshot =
            querySnapshot.docs.first;
        return localUser.User.fromFirestore(docSnapshot);
      } else {
        return null; // User not found
      }
    } catch (e) {
      debugPrint("Error getting user by email: $e");
      return null;
    }
  }

  Future<void> saveUser(localUser.User user) async {
    try {
      await _db
          .collection('users')
          .doc(user.uid)
          .set(user.toMap(), SetOptions(merge: true));
      debugPrint('User saved/updated successfully');
    } catch (e) {
      debugPrint("Error saving/updating user: $e");
    }
  }

  Future<void> deleteUser(String uid) async {
    try {
      await _db.collection('users').doc(uid).delete();
      debugPrint('User deleted successfully');
    } catch (e) {
      debugPrint("Error deleting user: $e");
    }
  }

  Future<localUser.User?> getCurrentUser() async {
    try {
      User? firebaseUser = _auth.currentUser;
      if (firebaseUser != null) {
        return await getUserByUid(firebaseUser.uid);
      } else {
        return null; // No user signed in
      }
    } catch (e) {
      debugPrint("Error getting current user: $e");
      return null;
    }
  }
}
