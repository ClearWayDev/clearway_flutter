import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:clearway/services/imagedescription.dart';
import 'package:clearway/constants/tts_messages.dart';
import 'package:flutter/foundation.dart';
import 'package:clearway/utils/top_snackbar.dart';

class AccessMediaScreen extends StatefulWidget {
  const AccessMediaScreen({super.key});

  @override
  State<AccessMediaScreen> createState() => _AccessMediaScreenState();
}

class _AccessMediaScreenState extends State<AccessMediaScreen> {
   bool _isLoading = false;
  final ImageDescriptionService _imageDescriptionService = ImageDescriptionService();

  @override
  void initState() {
    super.initState();

    Future.delayed(const Duration(milliseconds: 500), () {
          // Describe the screen
          _imageDescriptionService.speak(TtsMessages.accessMediaScreen);
        });
  }

  void _previousStep() {
    // Handle back button press
    Navigator.pop(context);
  }

    Future<void> _hardwareAccess() async {
    if (kIsWeb) {
      Navigator.pushNamed(context, '/signin');
      return;
    }

    _imageDescriptionService.stopSpeak();
    setState(() => _isLoading = true);

    try {
      // Request permissions only on mobile platforms
      final List<Permission> permissionsToRequest = [
        Permission.camera,
        Permission.microphone,
        Permission.locationWhenInUse,
      ];

      Map<Permission, PermissionStatus> statuses = await permissionsToRequest.request();
      
      // Check if all permissions are granted
      bool allGranted = statuses.values.every((status) => status == PermissionStatus.granted);
      
      if (!allGranted) {
        // Show which permissions were denied
        List<String> deniedPermissions = [];
        statuses.forEach((permission, status) {
          if (status != PermissionStatus.granted) {
            switch (permission) {
              case Permission.camera:
                deniedPermissions.add('Camera');
                break;
              case Permission.microphone:
                deniedPermissions.add('Microphone');
                break;
              case Permission.locationWhenInUse:
                deniedPermissions.add('Location');
                break;
            }
          }
        });
        
        if (deniedPermissions.isNotEmpty) {
        showTopSnackBar(context, 'The following permissions were denied: ${deniedPermissions.join(', ')}. '
            'You can enable them later in your device settings if needed.', type: TopSnackBarType.success);
        }
      }
    } catch (e) {
        showTopSnackBar(context,'an error occured. please try again', type: TopSnackBarType.error);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
        ImageDescriptionService().stopSpeak();
        Future.delayed(const Duration(milliseconds: 500), () {
          Navigator.pushNamed(context, '/signin');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            // Back button
            Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: _previousStep,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Title
            Text(
              'Hardware Access',
              style: GoogleFonts.urbanist(
                fontSize: 30,
                fontWeight: FontWeight.w700,
                height: 1.3,
                letterSpacing: -0.01,
                color: const Color(0xFF1E232C),
                shadows: const [
                  Shadow(
                    offset: Offset(0, 2),
                    blurRadius: 4,
                    color: Color(0x40000000),
                  ),
                ],
              ),
            ),

            const Spacer(),

            // Image
            Center(
              child: Image.asset(
                'assets/image/app-permission.png',
                width: 204,
                height: 280,
              ),
            ),

            const SizedBox(height: 24),

            // Subheading
            const Text(
              'Microphone, Camera & Location',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            // Description
            const Text(
              'To make video calls, give access to your microphone & camera. To use location, please give access to location.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),

            const Spacer(),

            // Give Access Button
            SizedBox(
              width: 331,
              height: 56,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: _isLoading ? null : _hardwareAccess,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Give Access',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}