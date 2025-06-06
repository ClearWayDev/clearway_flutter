import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:clearway/providers/user_state.dart';
import 'package:clearway/services/authservice.dart';

class GuideProfileScreen extends ConsumerStatefulWidget {
  const GuideProfileScreen({super.key});

  @override
  ConsumerState<GuideProfileScreen> createState() => _GuideProfileScreenState();
}

class _GuideProfileScreenState extends ConsumerState<GuideProfileScreen> {
  final AuthService _authService = AuthService();

  bool _editing = false;
  bool _loading = true;
  bool _saving = false;

  final _usernameController = TextEditingController();
  final _usernameFocusNode = FocusNode();
  String _username = '';
  String _email = '';
  String _role = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() async {
    final uid = ref.read(userProvider)?.uid;
    if (uid != null) {
      final data = await _authService.getUserDetails(uid);
      if (data != null) {
        setState(() {
          _username = data['username'] ?? '';
          _email = data['email'] ?? '';
          _role = data['userType'].toString().split('.').last;
          _usernameController.text = _username;
          _loading = false;
        });
      } else {
        setState(() {
          _loading = false;
        });
      }
    } else {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _usernameFocusNode.dispose();
    super.dispose();
  }

  void _enableEdit() {
    setState(() {
      _editing = true;
    });
    Future.delayed(const Duration(milliseconds: 100), () {
      _usernameFocusNode.requestFocus();
    });
  }

  void _cancelEdit() {
    setState(() {
      _editing = false;
      _usernameController.text = _username;
    });
    _usernameFocusNode.unfocus();
  }

  void _saveUsername() async {
    final updatedUsername = _usernameController.text.trim();
    
    if (updatedUsername.isEmpty) {
      return;
    }

    if (updatedUsername == _username) {
      setState(() => _editing = false);
      _usernameFocusNode.unfocus();
      return;
    }

    setState(() => _saving = true);

    final uid = ref.read(userProvider)?.uid;
    if (uid != null) {
      try {
        final success = await _authService.updateUsername(uid, updatedUsername);
        if (success) {
          setState(() {
            _username = updatedUsername;
            _editing = false;
            _saving = false;
          });
          _usernameFocusNode.unfocus();
          ref.read(userProvider.notifier).updateUsername(updatedUsername);
        } else {
          setState(() => _saving = false);
        }
      } catch (e) {
        setState(() => _saving = false);
      }
    } else {
      setState(() => _saving = false);
    }
  }

  void _logout() async {
    await _authService.signOut();
    ref.read(userProvider.notifier).logout();

    if (context.mounted) {
      Navigator.pushReplacementNamed(context, '/signin');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text('Profile'),
        automaticallyImplyLeading: false,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Your Profile',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _usernameController,
                    focusNode: _usernameFocusNode,
                    enabled: !_saving,
                    readOnly: !_editing,
                    decoration: InputDecoration(
                      labelText: 'Username',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: _editing ? Colors.white : Colors.grey.shade100,
                      suffixIcon: _saving
                          ? const Padding(
                              padding: EdgeInsets.all(12.0),
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            )
                          : _editing
                              ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.check, color: Colors.green),
                                      onPressed: _saveUsername,
                                      tooltip: 'Save username',
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.close, color: Colors.red),
                                      onPressed: _cancelEdit,
                                      tooltip: 'Cancel editing',
                                    ),
                                  ],
                                )
                              : IconButton(
                                  icon: const Icon(Icons.edit),
                                  onPressed: _enableEdit,
                                  tooltip: 'Edit username',
                                ),
                    ),
                    onSubmitted: _editing ? (_) => _saveUsername() : null,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: TextEditingController(text: _email),
                    enabled: false,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: TextEditingController(text: _role),
                    enabled: false,
                    decoration: InputDecoration(
                      labelText: 'Role',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pushNamed(context, '/forgot-password');
                          },
                          icon: const Icon(Icons.lock_reset),
                          label: const Text('Reset Password'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _logout,
                          icon: const Icon(Icons.logout),
                          label: const Text('Logout'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}