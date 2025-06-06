import 'dart:typed_data';
import 'dart:io' show File; // Only used on mobile

import 'package:flutter/foundation.dart'; // for kIsWeb
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

class ImageDescriptionService {
  final ImagePicker _picker = ImagePicker();
  final FlutterTts _flutterTts = FlutterTts();
  final String _geminiApiKey =
      "AIzaSyBoGLXppwecH6WXz75fmc0w0YwiqIxsw_k"; // Store securely in production

  /// Request camera permission before capture
  Future<bool> _requestCameraPermission() async {
    print("🔐 Checking camera permission...");
    final status = await Permission.camera.status;
    if (!status.isGranted) {
      print("📛 Camera permission not granted. Requesting...");
      final result = await Permission.camera.request();
      if (!result.isGranted) {
        print("❌ Camera permission denied.");
      } else {
        print("✅ Camera permission granted.");
      }
      return result.isGranted;
    }
    print("✅ Camera permission already granted.");
    return true;
  }

  /// Capture photo using camera
  Future<XFile?> capturePhoto() async {
    if (!kIsWeb) {
      final permissionGranted = await _requestCameraPermission();
      if (!permissionGranted) {
        return null;
      }
    }

    try {
      print('📷 Opening camera...');
      final image = await _picker.pickImage(source: ImageSource.camera);
      print('📥 Image captured: ${image?.path}');
      return image;
    } catch (e) {
      print('❌ Error opening camera: $e');
      return null;
    }
  }

  /// Describe the image using Gemini
  Future<String> describeImage(XFile imageFile) async {
    print("🧠 Invoking describeImage()...");

    final model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: _geminiApiKey,
      generationConfig: GenerationConfig(maxOutputTokens: 2048),
    );

    try {
      Uint8List imageBytes;

      if (kIsWeb) {
        imageBytes = await imageFile.readAsBytes();
      } else {
        final file = File(imageFile.path);
        imageBytes = await file.readAsBytes();
      }

      print("📤 Image read as bytes. Sending to Gemini...");

      final response = await model.generateContent([
        Content.multi([
          TextPart(
            "You are assisting a blind person in navigating their environment. "
            "Look at this image and answer clearly: "
            "- Can the person move forward safely? "
            "- Are there any objects or people that may be moving in front of them? "
            "- Mention any obstacles or dangers (like steps, walls, vehicles, or other people). "
            "Keep the description clear and short so it can be spoken by a voice assistant.",
          ),

          DataPart('image/jpeg', imageBytes),
        ]),
      ]);

      final result = response.text ?? "No description was generated.";
      print("📩 Gemini response: $result");

      return result;
    } catch (e) {
      print("❌ Error in describeImage(): $e");
      return "Error describing the image.";
    }
  }

  /// Speak the description using TTS
  Future<void> speak(String text) async {
    print("🔊 Invoking speak()...");
    try {
      await _flutterTts.stop();
      await _flutterTts.setLanguage("en-US");
      await _flutterTts.setSpeechRate(0.5);
      await _flutterTts.setPitch(1.0);
      print("📣 Speaking: $text");
      await _flutterTts.speak(text);
    } catch (e) {
      print("❌ Error in TTS: $e");
    }
  }

  Future<void> stopSpeak() async {
  print("🛑 Stopping speech...");
  try {
    await _flutterTts.stop();
    print("✅ Speech stopped successfully");
  } catch (e) {
    print("❌ Error stopping speech: $e");
  }
}

  /// Full pipeline: capture, describe, speak
  Future<String?> captureDescribeSpeak() async {
    print("🚀 Starting captureDescribeSpeak() pipeline...");

    final photo = await capturePhoto();
    if (photo == null) {
      print("❗ Pipeline stopped: No photo captured.");
      return null;
    }

    final description = await describeImage(photo);
    await speak(description);

    print("✅ captureDescribeSpeak() completed.");
    return description;
  }
}
