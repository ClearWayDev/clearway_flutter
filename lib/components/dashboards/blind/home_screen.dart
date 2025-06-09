import 'package:clearway/services/imagedescription.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:clearway/constants/tts_messages.dart';
import 'package:clearway/widgets/blind_popup.dart';
import 'package:clearway/utils/tap_handler.dart';

class BlindHomeScreen extends ConsumerStatefulWidget {
  const BlindHomeScreen({super.key});
  
  @override
  ConsumerState<BlindHomeScreen> createState() => _BlindHomeScreenState();
}

class _BlindHomeScreenState extends ConsumerState<BlindHomeScreen> {
  final ImageDescriptionService _imageDescriptionService = ImageDescriptionService();
  
  bool _showAIPopup = false;
  bool _showVideoCallPopup = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 300), () {
      // Describe the screen
      _imageDescriptionService.speak(TtsMessages.dashboardScreen);
    });
  }

  // Main screen tap handlers
  void _handleDoubleTap() async {
    await _imageDescriptionService.stopSpeak();
    await Future.delayed(const Duration(milliseconds: 800));
    await _imageDescriptionService.speak(
  "AI assistance activated. To begin, please double tap the screen. "
  "To exit this feature, tap three times."
);
    
    setState(() {
      _showAIPopup = true;
    });
  }

  void _handleTripleTap() async {
    await _imageDescriptionService.stopSpeak();
    await Future.delayed(const Duration(milliseconds: 800));
    await _imageDescriptionService.speak(
  "Video call feature activated. Double tap the screen to place a call. "
  "To exit this feature, tap three times."
);
    
    setState(() {
      _showVideoCallPopup = true;
    });
  }
  void _handleAIDoubleTap() async {
  // Prevent multiple double-taps from re-triggering
  if (_imageDescriptionService.isLooping) return;

  await _imageDescriptionService.stopSpeak();
  await Future.delayed(const Duration(milliseconds: 1000));

  await _imageDescriptionService.speak("Capturing. Please keep the back camera facing forward.");

  final description = await _imageDescriptionService.captureDescribeSpeak();

  if (description == null) {
    await _imageDescriptionService.stopSpeak();
    await Future.delayed(const Duration(seconds: 1));
  } else {
    print("AI Description: $description");
  }
}

void _handleAITripleTap() async {
  await _imageDescriptionService.stopSpeak();
  await Future.delayed(const Duration(milliseconds: 800));

  // Stop captureDescribeSpeak if it's running
  if (_imageDescriptionService.isLooping) {
    await _imageDescriptionService.captureDescribeSpeak();
  }
  _closeAIPopup();
}
  void _closeAIPopup() async {
        await Future.delayed(const Duration(milliseconds: 500));
    setState(() {
      _showAIPopup = false;
    });
    _imageDescriptionService.speak("AI feature closed. Please tap twice for AI assistance or three times for video call feature.");
  }

  // Video Call Popup handlers
  void _handleVideoCallDoubleTap() async {
    await _imageDescriptionService.stopSpeak();
    await Future.delayed(const Duration(seconds: 1));
    await _imageDescriptionService.speak("Starting video call...");
  }

  void _handleVideoCallTripleTap() async {
        await _imageDescriptionService.stopSpeak();
        await Future.delayed(const Duration(milliseconds: 800));
    _closeVideoCallPopup();
  }

  void _closeVideoCallPopup() async {
        await Future.delayed(const Duration(milliseconds: 500));
    setState(() {
      _showVideoCallPopup = false;
    });
    _imageDescriptionService.speak("Video call feature closed. Please tap twice for AI assistance or three times for video call feature.");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Main screen
          TapHandlerWidget(
            onDoubleTap: _handleDoubleTap,
            onTripleTap: _handleTripleTap,
            child: Container(
              color: Colors.grey.shade300,
              width: double.infinity,
              height: double.infinity,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      'assets/icon/tap_icon.png',
                      width: 120,
                      height: 120,
                    ),
                    const SizedBox(height: 36),
                    const Text(
                      'Tap twice for AI assistance\nTap three times for video call',
                      style: TextStyle(color: Colors.black54, fontSize: 20),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // AI Popup
          if (_showAIPopup)
            BlindPopupWidget(
              title: "AI Assistant",
              subtitle: "Choose your AI action",
              onDoubleTap: _handleAIDoubleTap,
              onTripleTap: _handleAITripleTap,
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.camera_alt,
                    size: 60,
                    color: Colors.blue.shade600,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "AI Vision Ready",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          
          // Video Call Popup
          if (_showVideoCallPopup)
            BlindPopupWidget(
              title: "Video Call",
              subtitle: "Choose your call option",
              onDoubleTap: _handleVideoCallDoubleTap,
              onTripleTap: _handleVideoCallTripleTap,
              backgroundColor: Colors.green.shade50,
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.video_call,
                    size: 60,
                    color: Colors.green.shade600,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Call System Ready",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}