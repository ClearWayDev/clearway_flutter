import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:clearway/services/imagedescription.dart';
import 'package:clearway/constants/tts_messages.dart';
import 'package:clearway/providers/user_state.dart';
import 'package:clearway/services/authservice.dart';
import 'package:clearway/widgets/location_picker.dart';

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
  bool _saving = false;
  bool _keyboardVisible = false;
  
  // Location related variables
  bool _editingLocation = false;
  bool _savingLocation = false;
  LatLng? _selectedLocation;
  LatLng? _originalLocation;
  String _locationText = 'Enter a familiar location for guidance.';
  bool _showLocationPicker = false;
  String? _locationValidationError;

  final _usernameController = TextEditingController();
  final _usernameFocusNode = FocusNode();
  String _username = '';
  String _email = '';
  String _role = '';

  @override
  void initState() {
    super.initState();
    
    // Listen to focus changes to track keyboard visibility
    _usernameFocusNode.addListener(() {
      setState(() {
        _keyboardVisible = _usernameFocusNode.hasFocus;
      });
    });
    
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
            
            // Load location data if exists
            if (data['location'] != null) {
                _selectedLocation = data['location'] as LatLng;
                _originalLocation = _selectedLocation;
                  _locationText = 'Lat: ${_selectedLocation!.latitude.toStringAsFixed(4)}, '
                 'Lng: ${_selectedLocation!.longitude.toStringAsFixed(4)}';
            }
            
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
    Future.delayed(const Duration(milliseconds: 100), () {
      _usernameFocusNode.requestFocus();
    });
    await Future.delayed(const Duration(milliseconds: 400));
    _imageDescriptionService.speak("Username editing enabled.");
  }

  void _cancelEdit() {
    setState(() {
      _editing = false;
      _usernameController.text = _username;
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

  // Location related methods
  void _enableLocationEdit() async {
    setState(() {
      _editingLocation = true;
      _locationValidationError = null;
    });
    await _imageDescriptionService.stopSpeak();
    await Future.delayed(const Duration(milliseconds: 400));
    _imageDescriptionService.speak("Location editing enabled. Tap to select a new location.");
  }

  void _cancelLocationEdit() {
    setState(() {
      _editingLocation = false;
      _selectedLocation = _originalLocation;
      if (_originalLocation != null) {
        _locationText = 'Lat: ${_originalLocation!.latitude.toStringAsFixed(4)}, '
                       'Lng: ${_originalLocation!.longitude.toStringAsFixed(4)}';
      } else {
        _locationText = 'Enter a familiar location for guidance.';
      }
      _locationValidationError = null;
    });
    _imageDescriptionService.speak("Location editing cancelled.");
  }

  void _saveLocation() async {
    if (_selectedLocation == null) {
      setState(() {
        _locationValidationError = "Please select a location.";
      });
      _imageDescriptionService.speak("Please select a location first.");
      return;
    }

    // Check if location actually changed
    if (_originalLocation != null && 
        _selectedLocation!.latitude == _originalLocation!.latitude &&
        _selectedLocation!.longitude == _originalLocation!.longitude) {
      setState(() => _editingLocation = false);
      _imageDescriptionService.speak("No changes made to location");
      return;
    }

    setState(() => _savingLocation = true);

    final uid = ref.read(userProvider)?.uid;
    if (uid != null) {
      try {
        final success = await _authService.updateUserLocation(uid, _selectedLocation);
        if (success) {
          setState(() {
            _originalLocation = _selectedLocation;
            _editingLocation = false;
            _savingLocation = false;
            _locationValidationError = null;
          });
          _imageDescriptionService.speak("Location updated successfully");
        } else {
          setState(() => _savingLocation = false);
          _imageDescriptionService.speak("Failed to update location. Please try again.");
        }
      } catch (e) {
        setState(() => _savingLocation = false);
        _imageDescriptionService.speak("Error updating location. Please try again.");
      }
    } else {
      setState(() => _savingLocation = false);
      _imageDescriptionService.speak("Error: User not found. Please try again.");
    }
  }

  void _openLocationPicker() {
    if (!_editingLocation) return;
    
    setState(() {
      _showLocationPicker = true;
    });
  }

  void _closeLocationPicker() {
    setState(() {
      _showLocationPicker = false;
    });
  }

  void _onLocationSelected(LatLng location) {
    setState(() {
      _selectedLocation = location;
      _locationText = 'Lat: ${location.latitude.toStringAsFixed(4)}, '
                      'Lng: ${location.longitude.toStringAsFixed(4)}';
      _showLocationPicker = false;
      _locationValidationError = null;
    });
    _imageDescriptionService.speak("Location selected: ${_locationText}");
  }

  void _logout() async {
    _imageDescriptionService.stopSpeak();
    await _authService.signOut();
    ref.read(userProvider.notifier).logout();
    if (context.mounted) {
      Navigator.pushReplacementNamed(context, '/signin');
    }
  }

  void _navigateToHome() {
    // Only navigate if not editing and keyboard is not visible
    if (!_editing && !_keyboardVisible && !_editingLocation && !_showLocationPicker) {
      _imageDescriptionService.stopSpeak();
      Future.delayed(const Duration(milliseconds: 500), () {
        Navigator.pushReplacementNamed(context, '/dashboard/blind/home');
      });
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
          : Stack(
              children: [
                Column(
                  children: [
                    // Profile content with proper spacing
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Your Profile',
                              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 12),
                            
                            // Username Field
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
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
                            const SizedBox(height: 10),
                            
                            // Email Field
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
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              ),
                            ),
                            const SizedBox(height: 10),
                            
                            // Role Field
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
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              ),
                            ),
                            const SizedBox(height: 12),
                            
                            // Location Selection for Blind Users
                            Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: _locationValidationError != null
                                      ? Colors.red
                                      : Colors.grey.shade300
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: InkWell(
                                onTap: _editingLocation ? _openLocationPicker : null,
                                borderRadius: BorderRadius.circular(8),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.location_on,
                                        color: _selectedLocation != null ? Colors.teal : Colors.grey,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              'Location',
                                              style: GoogleFonts.urbanist(
                                                fontSize: 12,
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              _locationText,
                                              style: GoogleFonts.urbanist(
                                                fontSize: 14,
                                                color: _selectedLocation != null
                                                    ? Colors.black
                                                    : Colors.grey.shade500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (_savingLocation)
                                        const Padding(
                                          padding: EdgeInsets.all(6.0),
                                          child: SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(strokeWidth: 2),
                                          ),
                                        )
                                      else if (_editingLocation)
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.check, color: Colors.green),
                                              onPressed: _saveLocation,
                                              tooltip: 'Save location',
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.close, color: Colors.red),
                                              onPressed: _cancelLocationEdit,
                                              tooltip: 'Cancel editing',
                                            ),
                                          ],
                                        )
                                      else
                                        IconButton(
                                          icon: const Icon(Icons.edit),
                                          onPressed: _enableLocationEdit,
                                          tooltip: 'Edit location',
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            
                            // Location Validation Error
                            if (_locationValidationError != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 6, left: 12),
                                child: Text(
                                  _locationValidationError!,
                                  style: const TextStyle(
                                    fontFamily: 'Urbanist',
                                    fontSize: 12,
                                    color: Colors.red,
                                  ),
                                ),
                              ),
                            
                            const SizedBox(height: 16),
                            
                            // Action Buttons
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      Navigator.pushNamed(context, '/reset-password');
                                    },
                                    icon: const Icon(Icons.lock_reset, size: 18),
                                    label: const Text('Reset Password', style: TextStyle(fontSize: 14)),
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: _logout,
                                    icon: const Icon(Icons.logout, size: 18),
                                    label: const Text('Logout', style: TextStyle(fontSize: 14)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            
                            // Add extra space when keyboard is visible
                            if (_keyboardVisible) const SizedBox(height: 80),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                
                // Bottom navigation area - Takes all remaining space
                if (!_editing && !_keyboardVisible && !_editingLocation && !_showLocationPicker)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _navigateToHome,
                      child: Container(
                        width: double.infinity,
                        height: MediaQuery.of(context).size.height * 0.35, // Takes 35% of screen height
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          border: Border(
                            top: BorderSide(color: Colors.grey.shade300, width: 1),
                          ),
                        ),
                        child: const Center(
                          child: Text(
                            'Tap here to return to Home',
                            style: TextStyle(fontSize: 18, color: Colors.black54),
                          ),
                        ),
                      ),
                    ),
                  ),
                
                // Location Picker Overlay
                if (_showLocationPicker)
                  LocationPickerOverlay(
                    initialLocation: _selectedLocation,
                    onLocationSelected: _onLocationSelected,
                    onClose: _closeLocationPicker,
                  ),
              ],
            ),
    );
  }
}