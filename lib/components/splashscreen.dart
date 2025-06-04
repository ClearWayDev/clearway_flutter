import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:clearway/providers/auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget  {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);

    _controller.forward();

    // After splash duration, navigate to home
    Timer(const Duration(seconds: 3), _navigateUser);
  }

   void _navigateUser() {
  
    final user = ref.read(authStateProvider).value;
    if (user != null) {
      Navigator.pushReplacementNamed(context, '/dashboard');
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
