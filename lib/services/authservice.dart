import 'package:clearway/models/user.dart';
import 'package:clearway/models/user_info.dart';
import 'package:clearway/services/firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';
class AuthService {
  final fb.FirebaseAuth _firebaseAuth = fb.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirestoreService _firestoreService = FirestoreService();

  // Sign up
  Future<UserInfo?> signUp(
  String email,
  String password,
  String name,
  UserType userType,
  String fcmToken,
  LatLng? location, // <-- Add optional location param
) async {
  final cred = await _firebaseAuth.createUserWithEmailAndPassword(
    email: email,
    password: password,
  );

  await cred.user!.updateDisplayName(name);

  final user = User(
    id: cred.user!.uid,
    name: name,
    email: email,
    userType: userType,
  );

  // Save user data to Firestore
  await _firestore.collection('users').doc(user.id).set(user.toMap());

  // Save FCM token
  await _firestoreService.addFcmToken(user.id, fcmToken);

   //Save location to 'location' collection if exists
    if (location != null) {
    await _firestore.collection('locations').doc(user.id).set({
      'location': GeoPoint(location.latitude, location.longitude),
    });
  }
  return UserInfo(
    uid: user.id,
    userType: userType,
    fcmToken: fcmToken,
    username: name,
  );
}


  // Sign in
  Future<UserInfo?> signIn(String email, String password, String fcmToken) async {
    final cred = await _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    final fbUser = cred.user!;
    final doc = await _firestore.collection('users').doc(fbUser.uid).get();

    if (!doc.exists) return null;

    final data = doc.data()!;
    final userType = data['isBlind'] == true ? UserType.blind : UserType.volunteer;

    // Save FCM token
    await _firestoreService.addFcmToken(fbUser.uid, fcmToken);

      await cred.user!.updateDisplayName(data['name']);

    return UserInfo(
      uid: fbUser.uid,
      userType: userType,
      fcmToken: fcmToken,
      username: data['name'],
    );
  }

  Future<UserInfo?> getCurrentUserData() async {
  final fb.User? currentUser = _firebaseAuth.currentUser;
  if (currentUser == null) {
    // No user logged in
    return null;
  }

  final uid = currentUser.uid;

  final doc = await _firestore.collection('users').doc(uid).get();
  if (!doc.exists) return null;

  final data = doc.data()!;

  final userType = (data['isBlind'] == true)
      ? UserType.blind
      : UserType.volunteer;

  String fcmToken = '';
  if (data.containsKey('fcmToken')) {
    fcmToken = data['fcmToken'] as String;
  }

  return UserInfo(
    uid: uid,
    userType: userType,
    fcmToken: fcmToken,
    username: data['name'] ?? '',
  );
}

Future<Map<String, dynamic>?> getUserDetails(String uid) async {
  // Get user document
  final userDoc = await _firestore.collection('users').doc(uid).get();
  if (!userDoc.exists) return null;

  final data = userDoc.data()!;
  LatLng? location;

  // Try to get location document
  final locationDoc = await _firestore.collection('locations').doc(uid).get();
  if (locationDoc.exists) {
    final geo = locationDoc['location'];
    if (geo is GeoPoint) {
      location = LatLng(geo.latitude, geo.longitude);
    }
  }

  return {
    'username': data['name'] ?? '',
    'email': data['email'] ?? '',
    'userType': data['isBlind'] == true ? UserType.blind : UserType.volunteer,
    if (location != null) 'location': location,
  };
}

Future<bool> updateUsername(String uid, String newName) async {
    // Update Firestore
    await _firestore.collection('users').doc(uid).update({'name': newName});

    // Update Firebase Auth display name
    final user = _firebaseAuth.currentUser;
    if (user != null && user.uid == uid) {
      await user.updateDisplayName(newName);
    }

    return true;
}

Future<bool> updateUserLocation(String uid, LatLng? selectedLocation) async {
  if (selectedLocation == null) return false;

  await _firestore.collection('locations').doc(uid).set({
    'location': GeoPoint(selectedLocation.latitude, selectedLocation.longitude),
  });

  return true;
}

  // Sign out
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }

  // Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    await _firebaseAuth.sendPasswordResetEmail(email: email);
  }
}
