import 'package:flutter/material.dart';

class GuideProfileScreen extends StatelessWidget {
  const GuideProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        automaticallyImplyLeading: false,
      ),
      body: const Center(
        child: Text(
          'Guide Profile',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}