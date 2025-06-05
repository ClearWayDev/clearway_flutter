import 'package:clearway/services/authservice.dart';
import 'package:clearway/services/imagedescription.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:clearway/providers/user_state.dart';

class GuideHomeScreen extends ConsumerStatefulWidget {
  const GuideHomeScreen({super.key});

  @override
  ConsumerState<GuideHomeScreen> createState() => _GuideHomeScreenState();
}

class _GuideHomeScreenState extends ConsumerState<GuideHomeScreen> {
  final AuthService _authService = AuthService();
  final ImageDescriptionService _imageDescriptionService = ImageDescriptionService();

  String? _description;
  bool _loading = false;

  void _signOut() async {
    await _authService.signOut();
    ref.read(userProvider.notifier).logout();
  }

  Future<void> _startCapture() async {
    setState(() => _loading = true);
    final result = await _imageDescriptionService.captureDescribeSpeak();
    setState(() {
      _description = result;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Guide User Home'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _signOut,
            tooltip: 'Sign Out',
          )
        ],
      ),
      body: Center(
        child: _loading
            ? const CircularProgressIndicator()
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Welcome, ${user?.username ?? 'User'}'),
                  const SizedBox(height: 10),
                  Text('User ID: ${user?.uid ?? 'N/A'}'),
                  Text('User Type: ${user?.userType.toString().split('.').last ?? 'N/A'}'),
                  Text('FCM Token: ${user?.fcmToken ?? 'N/A'}'),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: _startCapture,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text("Capture & Describe"),
                  ),
                  const SizedBox(height: 20),
                  if (_description != null)
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Text(
                        'Description: $_description',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}
