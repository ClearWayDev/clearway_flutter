import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:clearway/services/imagedescription.dart';
import 'package:clearway/constants/tts_messages.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';
// import 'package:flutter/foundation.dart';
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
     bool _isLoading = false;
  @override
  void initState() {
    super.initState();

    Future.delayed(const Duration(milliseconds: 300), () {
    // Describe the screen
    ImageDescriptionService().speak(TtsMessages.welcomeScreen);
  });
  }

 Future<void> _hardwareAccess() async {
   ImageDescriptionService().stopSpeak();
    await Future.delayed(const Duration(milliseconds: 1000));
    setState(() => _isLoading = true);

  if (kIsWeb) {
    setState(() => _isLoading = false);
    Navigator.pushNamed(context, '/signin');
    return;
  }

  final List<Permission> permissionsToRequest = [
    Permission.camera,
    Permission.microphone,
    Permission.locationWhenInUse,
  ];

  // Check if all permissions are already granted
  final statusesBefore = await Future.wait(permissionsToRequest.map((p) => p.status));
  final allGrantedBefore = statusesBefore.every((status) => status == PermissionStatus.granted);

  if (allGrantedBefore) {
    setState(() => _isLoading = false);
    Navigator.pushNamed(context, '/signin');
    return;
  }

  setState(() => _isLoading = false);
  Navigator.pushNamed(context, '/access-media');
}

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      body: SafeArea(
        child: Column(
          children: [
            // Logo
            Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.only(top: 16.0, left: 0),
                child: SizedBox(
                  width: 240,
                  height: 64,
                  child: Image.asset(
                    'assets/logo/app-logo.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    SizedBox(
                      width: 280,
                      height: 280,
                      child: Image.asset(
                        'assets/image/welcome-image.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Navigate Your World\nwith Confidence',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.urbanist(
                        fontWeight: FontWeight.w700,
                        fontSize: 26,
                        height: 1.2,
                        color: Colors.black,
                        shadows: const [
                          Shadow(
                            offset: Offset(0, 1),
                            blurRadius: 2,
                            color: Color(0x29000000),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'We empower visually impaired individuals with real-time guidance, merging traditional aids with modern technology for safer, independent mobility.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w400,
                        fontSize: 14,
                        height: 2,
                        color: const Color(0xFF606060),
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),

            // Bottom button
            Padding(
  padding: const EdgeInsets.fromLTRB(15, 0, 15, 20),
  child: SizedBox(
    width: double.infinity,
    height: 56,
    child: ElevatedButton(
      onPressed: _isLoading ? null : _hardwareAccess,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: _isLoading
          ? const SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : Text(
              'Explore',
              style: GoogleFonts.urbanist(
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: Colors.white,
              ),
            ),
    ),
  ),
),

          ],
        ),
      ),
    );
  }
}
