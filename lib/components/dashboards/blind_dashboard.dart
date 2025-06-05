// blind_dashboard.dart
import 'package:flutter/material.dart';

class BlindDashboard extends StatelessWidget {
  final Widget child;

  const BlindDashboard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
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

  void _onItemTapped(int index, BuildContext context) {
    final routes = ['/dashboard/blind/home', '/dashboard/blind/profile'];
    Navigator.pushReplacementNamed(context, routes[index]);
  }
}
