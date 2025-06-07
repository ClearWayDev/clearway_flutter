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
      case 2:
        _handleDoubleTap();
        break;
      case 3:
        _handleTripleTap();
        break;
      default:
        _handleInvalidTap();
        break;
    }
    
    // Reset tap count after processing
    _tapCount = 0;
    _lastTapTime = null;
  }

void _handleDoubleTap() async {
  await _imageDescriptionService.speak("AI assistance activated.");
  
  await _imageDescriptionService.stopSpeak();
  await Future.delayed(const Duration(seconds: 1));

  await _imageDescriptionService.speak("Capturing surroundings");

  final description = await _imageDescriptionService.captureDescribeSpeak();

  if (description == null) {
    await _imageDescriptionService.stopSpeak();
    await Future.delayed(const Duration(seconds: 1));
    _imageDescriptionService.speak("Capture stopped or failed. Try again.");
  } else {
    // Already spoken in captureDescribeSpeak()
    print("AI Description: $description");
  }
}

  void _handleTripleTap() {
    // Video call functionality
    _imageDescriptionService.speak("Video call feature activated.");
    // _triggerVideoCall();
  }

  void _handleInvalidTap() {
    // Invalid tap count - provide guidance
    _imageDescriptionService.speak(
      "Invalid input detected. Please tap twice for AI assistance or three times for video call feature. Try again."
    );
  }


  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        color: Colors.grey.shade300,
        width: double.infinity,
        height: double.infinity,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: _handleTap,
                child: Image.asset(
                  'assets/icon/tap_icon.png',
                  width: 120,
                  height: 120,
                ),
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
    );
  }
}