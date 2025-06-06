import 'package:clearway/services/imagedescription.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:clearway/constants/tts_messages.dart';

class BlindHomeScreen extends ConsumerStatefulWidget {
  const BlindHomeScreen({super.key});
  
  @override
  ConsumerState<BlindHomeScreen> createState() => _BlindHomeScreenState();
}

class _BlindHomeScreenState extends ConsumerState<BlindHomeScreen> {
      final ImageDescriptionService _imageDescriptionService = ImageDescriptionService();

  int _tapCount = 0;
  DateTime? _lastTapTime;
  static const Duration _tapTimeWindow = Duration(milliseconds: 500); // Time window for detecting multiple taps
  static const Duration _processingDelay = Duration(milliseconds: 1000); // Delay before processing taps

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 300), () {
      // Describe the screen
      _imageDescriptionService.speak(TtsMessages.dashboardScreen);
    });
  }

  void _handleTap() async {
    await _imageDescriptionService.stopSpeak();
    final now = DateTime.now();
    
    // Reset tap count if too much time has passed since last tap
    if (_lastTapTime != null && now.difference(_lastTapTime!) > _tapTimeWindow) {
      _tapCount = 0;
    }
    
    _tapCount++;
    _lastTapTime = now;
    
    // Cancel any existing timer and start a new one
    Future.delayed(_processingDelay, () {
      // Only process if this is still the latest tap sequence
      if (_lastTapTime != null && now.difference(_lastTapTime!) <= _processingDelay) {
        _processTaps();
      }
    });
  }

  void _processTaps() {
    switch (_tapCount) {
      case 1:
        _handleSingleTap();
        break;
      case 2:
        _handleDoubleTap();
        break;
      default:
        _handleInvalidTap();
        break;
    }
    
    // Reset tap count after processing
    _tapCount = 0;
    _lastTapTime = null;
  }

  void _handleSingleTap() {
    // AI assistance functionality
    _imageDescriptionService.speak("AI assistance activated. How can I help you?");
    // _triggerAIAssistance();
  }

  void _handleDoubleTap() {
    // Video call functionality
    _imageDescriptionService.speak("Video call feature activated.");
    // _triggerVideoCall();
  }

  void _handleInvalidTap() {
    // Invalid tap count - provide guidance
    _imageDescriptionService.speak(
      "Invalid input detected. Please tap once for AI assistance or twice for video call feature. Try again."
    );
  }

  // void _triggerAIAssistance() {
  //   // TODO: Implement AI assistance logic
  //   print("AI assistance triggered");
  //   // Navigate to AI assistance screen or start voice recognition
  //   // Example:
  //   // Navigator.pushNamed(context, '/ai-assistance');
  // }

  // void _triggerVideoCall() {
  //   // TODO: Implement video call logic
  //   print("Video call triggered");
  //   // Navigate to video call screen or start video call
  //   // Example:
  //   // Navigator.pushNamed(context, '/video-call');
  // }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      behavior: HitTestBehavior.opaque, // Ensures entire screen is tappable
      child: Container(
        color: Colors.grey.shade300,
        width: double.infinity,
        height: double.infinity,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.mic, color: Colors.white, size: 48),
              ),
              const SizedBox(height: 16),
              const Text(
                'Voice Assistant',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              const Text(
                'Tap once for AI assistance\nTap twice for video call',
                style: TextStyle(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}