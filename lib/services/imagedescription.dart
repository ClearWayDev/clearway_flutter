import 'dart:async';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:clearway/services/guidanceservice.dart';
import 'package:flutter/foundation.dart'; // for kIsWeb
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:image/image.dart' as img;

class ImageDescriptionService {
  final FlutterTts _flutterTts = FlutterTts();
  final String _geminiApiKey = "AIzaSyDYSPxTvZQsjES1m-11lotUSXb2eJAK9Vs";

  bool _isLooping = false;
  bool _stopRequested = false;

  CameraController? _cameraController;

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    final rearCamera = cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.back,
    );
    _cameraController = CameraController(
      rearCamera,
      ResolutionPreset.medium,
      enableAudio: false,
    );
    await _cameraController!.initialize();
    print("📷 Camera initialized.");
  }

  Future<XFile?> autoCaptureImage() async {
    try {
      if (_cameraController == null ||
          !_cameraController!.value.isInitialized) {
        await _initializeCamera();
      }

      print("📸 Auto-capturing image...");
      return await _cameraController!.takePicture();
    } catch (e) {
      print("❌ Failed to auto-capture: $e");
      return null;
    }
  }

  Future<Uint8List> compressImage(XFile imageFile) async {
    print("📉 Compressing image...");
    final bytes = await imageFile.readAsBytes();
    final original = img.decodeImage(bytes);

    if (original == null) {
      throw Exception("Failed to decode image");
    }

    final resized = img.copyResize(original, width: 512);
    final compressed = img.encodeJpg(resized, quality: 70);
    return Uint8List.fromList(compressed);
  }

  Future<String> describeImage(
    Uint8List imageBytes,
    String guidanceText,
  ) async {
    print("🧠 Describing image with navigation...");

    final model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: _geminiApiKey,
      generationConfig: GenerationConfig(maxOutputTokens: 2048),
    );

    try {
      final response = await model.generateContent([
        Content.multi([
          TextPart(
            "You are helping a blind person navigate their surroundings using an image and navigation directions.\n\n"
            "First, look at the image and answer clearly:\n"
            "- Can the person move forward safely?\n"
            "- Are there any objects or people in front?\n"
            "- Mention any obstacles or dangers briefly.\n\n"
            "Then, consider the following navigation directions from Google Maps:\n"
            "$guidanceText\n\n"
            "From these directions, summarize only the **first meaningful instruction** the person should follow.\n"
            "Be clear and speak-friendly.",
          ),
          DataPart('image/jpeg', imageBytes),
        ]),
      ]);

      return response.text ?? "No description was generated.";
    } catch (e) {
      print("❌ Gemini failed: $e");
      return "Error describing the image: $e";
    }
  }

  Future<void> speak(String text) async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setPitch(1.0);
    await _flutterTts.speak(text);
  }

  Future<void> stopSpeak() async {
    print("🛑 Stopping speech...");
    try {
      await _flutterTts.stop();
    } catch (e) {
      print("❌ Error stopping speech: $e");
    }
  }

  Future<String?> captureDescribeSpeak() async {
    if (_isLooping) {
      _stopRequested = true;
      return null;
    }

    _isLooping = true;
    _stopRequested = false;
    String? lastDescription;

    while (!_stopRequested) {
      final photo = await autoCaptureImage();
      if (photo == null) break;

      final compressedBytes = await compressImage(photo);

      final guidanceService = GuidanceService();
      String guidance = await guidanceService.getGuidance("Galle fort");

      final imageDescriptionText = await describeImage(
        compressedBytes,
        guidance,
      );

      print("🧭 Guidance received: $guidance");

      await speak(imageDescriptionText);

      lastDescription = imageDescriptionText;

      if (_stopRequested) break;

      print("⏳ Waiting 10 seconds...");
      for (int i = 0; i < 10; i++) {
        if (_stopRequested) break;
        await Future.delayed(Duration(seconds: 1));
      }
    }

    _isLooping = false;
    _stopRequested = false;
    await _cameraController?.dispose();
    _cameraController = null;

    print("✅ Loop finished.");
    return lastDescription;
  }
}
