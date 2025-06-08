import 'dart:async';
import 'package:camera/camera.dart';
import 'package:clearway/services/guidanceservice.dart';
import 'package:flutter/foundation.dart'; // for kIsWeb
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:image/image.dart' as img;
import 'package:permission_handler/permission_handler.dart';

class ImageDescriptionService {
  final FlutterTts _flutterTts = FlutterTts();
  final String _geminiApiKey = 'AIzaSyBoGLXppwecH6WXz75fmc0w0YwiqIxsw_k';

  bool _isLooping = false;
  bool _stopRequested = false;

  CameraController? _cameraController;

  Future<bool> _requestCameraPermission() async {
    print("🔐 Checking camera permission...");
    final status = await Permission.camera.status;
    if (!status.isGranted) {
      final result = await Permission.camera.request();
      return result.isGranted;
    }
    return true;
  }

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
    if (!kIsWeb) {
      final permissionGranted = await _requestCameraPermission();
      if (!permissionGranted) {
        print("❌ Camera permission denied.");
        return null;
      }
    }

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

    final resized = img.copyResize(original, width: 512); // smaller width
    final compressed = img.encodeJpg(resized, quality: 70); // medium quality
    return Uint8List.fromList(compressed);
  }

  Future<String> describeImage(Uint8List imageBytes) async {
    print("🧠 Describing image...");

    final model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: _geminiApiKey,
      generationConfig: GenerationConfig(maxOutputTokens: 2048),
    );

    try {
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

      return response.text ?? "No description was generated.";
    } catch (e) {
      print("❌ Gemini failed: $e");
      return "Error describing the image.";
    }
  }

  Future<void> speak(String text) async {
    try {
      await _flutterTts.stop();
      await _flutterTts.setLanguage("en-US");
      await _flutterTts.setSpeechRate(0.5);
      await _flutterTts.setPitch(1.0);
      print("📣 Speaking: $text");
      await _flutterTts.speak(text);
    } catch (e) {
      print("❌ TTS Error: $e");
    }
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
      final imageDescriptionText = await describeImage(compressedBytes);
      final guidanceService = GuidanceService();
      final guidance = await guidanceService.getGuidance("Galle fort"); //todo : need to fetch destination from saved locartion

      final combinedText = "$imageDescriptionText. $guidance";
      await speak(combinedText);

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
