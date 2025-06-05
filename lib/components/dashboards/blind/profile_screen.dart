import 'package:flutter/material.dart';

class BlindProfileScreen extends StatelessWidget {
  const BlindProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        automaticallyImplyLeading: false,
      ),
      body: const Center(
        child: Text(
          'Blind User Profile',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}