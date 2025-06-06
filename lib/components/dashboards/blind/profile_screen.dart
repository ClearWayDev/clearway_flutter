import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:clearway/services/imagedescription.dart';
import 'package:clearway/constants/tts_messages.dart';
import 'package:clearway/providers/user_state.dart';
import 'package:clearway/services/authservice.dart';

class BlindProfileScreen extends ConsumerStatefulWidget {
  const BlindProfileScreen({super.key});

  @override
  ConsumerState<BlindProfileScreen> createState() => _BlindProfileScreenState();
}

class _BlindProfileScreenState extends ConsumerState<BlindProfileScreen> {
  final ImageDescriptionService _imageDescriptionService = ImageDescriptionService();
  final AuthService _authService = AuthService();

  bool _editing = false;
  bool _loading = true;
  bool _saving = false; // Add saving state

  final _usernameController = TextEditingController();
  final _usernameFocusNode = FocusNode(); // Add focus node
  String _username = '';
  String _email = '';
  String _role = '';

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 300), () async {
      _imageDescriptionService.speak(TtsMessages.profileScreen);

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
    });
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _usernameFocusNode.dispose();
    super.dispose();
  }

  void _enableEdit() async {
    setState(() {
      _editing = true;
    });
    await _imageDescriptionService.stopSpeak();
    // Auto-focus on the text field when editing starts
    Future.delayed(const Duration(milliseconds: 100), () {
      _usernameFocusNode.requestFocus();
    });
      await Future.delayed(const Duration(milliseconds: 400));
    // Provide audio feedback
    _imageDescriptionService.speak("Username editing enabled.");
  }

  void _cancelEdit() {
    setState(() {
      _editing = false;
      _usernameController.text = _username; // Reset to original value
    });
    _usernameFocusNode.unfocus();
    _imageDescriptionService.speak("Username editing cancelled.");
  }

  void _saveUsername() async {
    final updatedUsername = _usernameController.text.trim();
    
    if (updatedUsername.isEmpty) {
      _imageDescriptionService.speak("Username cannot be empty.");
      return;
    }

    if (updatedUsername == _username) {
      // No change, just exit edit mode
      setState(() => _editing = false);
      _usernameFocusNode.unfocus();
      _imageDescriptionService.speak("No changes made");
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
          _imageDescriptionService.speak("Username updated successfully");
        } else {
          setState(() => _saving = false);
          _imageDescriptionService.speak("Failed to update username. Please try again.");
        }
      } catch (e) {
        setState(() => _saving = false);
        _imageDescriptionService.speak("Error updating username. Please try again.");
      }
    } else {
      setState(() => _saving = false);
      _imageDescriptionService.speak("Error: User not found. Please try again.");
    }
  }

void _logout() async {
  _imageDescriptionService.stopSpeak();
  await Future.delayed(const Duration(milliseconds: 300));
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
          : Column(
              children: [
                // Top Half: Profile content
                Expanded(
                  child: Padding(
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
                          enabled: !_saving, // Disable during saving
                          readOnly: !_editing, // Use readOnly instead of enabled for better control
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
                ),

                // Bottom Half: Tap to go home
                GestureDetector(
                  onTap: () {
                    _imageDescriptionService.stopSpeak();
                    Future.delayed(const Duration(milliseconds: 500), () {
                      Navigator.pushReplacementNamed(context, '/dashboard/blind/home');
                    });
                  },
                  child: Container(
                    width: double.infinity,
                    height: MediaQuery.of(context).size.height * 0.4,
                    color: Colors.grey.shade200,
                    child: const Center(
                      child: Text(
                        'Tap here to return to Home',
                        style: TextStyle(fontSize: 16, color: Colors.black54),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}