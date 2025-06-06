import 'package:clearway/services/authservice.dart';
import 'package:clearway/services/imagedescription.dart';
import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:clearway/providers/user_state.dart';

class DashboardScreen extends ConsumerStatefulWidget  {
  DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  final AuthService _authService = AuthService();
  final ImageDescriptionService _imageDescriptionService = ImageDescriptionService();

  String? _description;
  bool _loading = false;

  void _signOut(BuildContext context) async {
    await _authService.signOut();
    // remove user state
    ref.read(userProvider.notifier).logout();
    Navigator.pushReplacementNamed(context, '/signin');
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
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _signOut(context),
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
                  Text('Welcome to Dashboard, ${user?.username ?? 'User'}!'),
                  Text('User Id, ${user?.uid ?? 'id'}!'),
                  Text('FCM token, ${user?.fcmToken ?? 'token'}!'),
                  Text('User type, ${user?.userType ?? 'type'}!'),
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
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: _startCapture,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text("Capture & Describe"),
                  ),
                ],
              ),
      ),
    );
  }
}
