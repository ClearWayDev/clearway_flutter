import 'package:clearway/services/imagedescription.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:clearway/providers/user_state.dart';

class BlindDashboard extends ConsumerWidget {
  final Widget child;

  const BlindDashboard({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Hi, ${user?.username ?? 'User'} 👋',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.grey,
                    child: Icon(Icons.notifications, size: 20, color: Colors.white),
                  ),
                ],
              ),
            ),
            Expanded(child: child),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _calculateSelectedIndex(context),
        onTap: (index) => _onItemTapped(index, context),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  int _calculateSelectedIndex(BuildContext context) {
    final uri = ModalRoute.of(context)?.settings.name ?? '';
    if (uri.contains('/home')) return 0;
    if (uri.contains('/profile')) return 1;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) async {
    final routes = ['/dashboard/blind/home', '/dashboard/blind/profile'];
    await ImageDescriptionService().stopSpeak();
    Future.delayed(const Duration(milliseconds: 300), () {
      Navigator.pushReplacementNamed(context, routes[index]);
    });
  }
}
