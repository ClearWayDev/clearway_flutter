import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<String?> getCurrentUserID() async {
    try {
      User? firebaseUser = _auth.currentUser;
      if (firebaseUser != null) {
        return _auth.currentUser!.uid;
      } else {
        return null; // No user signed in
      }
    } catch (e) {
      debugPrint("Error getting current user: $e");
      return null;
    }
  }

  Future<bool> isUserBlind(String uid) async {
    try {
      DocumentSnapshot doc = await _db.collection('users').doc(uid).get();
      if (doc.exists) {
        return doc['isBlind'];
      } else {
        return false; // User does not exist
      }
    } catch (e) {
      debugPrint("Error checking if user is blind: $e");
      return false;
    }
  }

  Future<String?> getFcmTokenByUid(String uid) async {
    try {
      DocumentSnapshot doc = await _db.collection('fcmtokens').doc(uid).get();
      if (doc.exists) {
        return doc['fcmToken'] as String?;
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  Future<void> addFcmToken(String uid, String fcmToken) async {
    try {
      await _db.collection('fcmtokens').doc(uid).set({
        'fcmToken': fcmToken,
      }, SetOptions(merge: true));
    } catch (e) {}
  }

  Future<void> addCallRequest(String uid) async {
    try {
      await _db.collection('callrequests').doc(uid).set({'req': true});
    } catch (e) {
      debugPrint("Error adding empty call request: $e");
    }
  }

  Future<void> removeCallRequest(String uid) async {
    try {
      await _db.collection('callrequests').doc(uid).delete();
    } catch (e) {
      debugPrint("Error removing call request: $e");
    }
  }

  Future<bool> doesCallRequestExist(String uid) async {
    try {
      DocumentSnapshot doc =
          await _db.collection('callrequests').doc(uid).get();
      return doc.exists;
    } catch (e) {
      debugPrint("Error checking call request existence: $e");
      return false;
    }
  }
}
