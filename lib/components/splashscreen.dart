import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:clearway/providers/auth_provider.dart';
import 'package:clearway/providers/user_state.dart';
import 'package:clearway/models/user.dart';
import 'package:clearway/services/authservice.dart';
import 'package:clearway/services/imagedescription.dart';
import 'package:clearway/constants/tts_messages.dart';

class SplashScreen extends ConsumerStatefulWidget  {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

    final AuthService _authService = AuthService();
      final ImageDescriptionService _imageDescriptionService = ImageDescriptionService();



  @override
void initState() {
  super.initState();
  _controller = AnimationController(
    duration: const Duration(seconds: 3),
    vsync: this,
  );
  _animation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);
  _controller.forward();
 
  _initializeApp();
}


Future<void> _initializeApp() async {

    await _imageDescriptionService.speak(TtsMessages.splashScreen);
  // Wait for Firebase Auth ready
  final fbUser = await ref.read(authStateProvider.future);

  if (fbUser != null) {
    // Fetch full user info from Firestore
    final userInfo = await _authService.getCurrentUserData();

    // Update userProvider with full user info
    if (userInfo != null) {
      ref.read(userProvider.notifier).setUser(userInfo);
    }
  } else {
    // No logged in user
    ref.read(userProvider.notifier).logout();
  }

  // Wait for the splash animation duration or any other delay you want
  await Future.delayed(const Duration(seconds: 3));

  // Then navigate
  _navigateUser();
}

    void _navigateUser() {
      final authState = ref.watch(authStateProvider).value;
      final userState = ref.watch(userProvider);
    if (authState != null) {
      if(userState?.userType == UserType.blind){
         Navigator.pushNamedAndRemoveUntil(context, '/dashboard/blind/home', (route) => false);
        } else {
        Navigator.pushNamedAndRemoveUntil(context, '/dashboard/guide/home', (route) => false);
      }
    } else {
      Navigator.pushReplacementNamed(context, '/welcome');
    }
  }
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildLoadingBar() {
    return Container(
      width: 282,
      height: 17,
      decoration: BoxDecoration(
        color: const Color(0xFFD9D9D9),
        borderRadius: BorderRadius.circular(10),
      ),
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: _animation.value,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:const Color(0xFF1E1E1E), // or your app background
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 314,
              height: 106,
              child: Image.asset(
                'assets/logo/app-logo.png',
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 40),
            _buildLoadingBar(),
          ],
        ),
      ),
    );
  }
}
