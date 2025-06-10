import 'dart:async';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:clearway/services/guidanceservice.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:image/image.dart' as img;
import 'package:cloud_firestore/cloud_firestore.dart';

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
    print("Camera initialized.");
  }

  Future<XFile?> autoCaptureImage() async {
    try {
      if (_cameraController == null ||
          !_cameraController!.value.isInitialized) {
        await _initializeCamera();
      }

      print("Auto-capturing image...");
      return await _cameraController!.takePicture();
    } catch (e) {
      print("Failed to auto-capture: $e");
      return null;
    }
  }

  Future<Uint8List> compressImage(XFile imageFile) async {
    print("Compressing image...");
    final bytes = await imageFile.readAsBytes();
    final original = img.decodeImage(bytes);

    if (original == null) {
      throw Exception("Failed to decode image");
    }

    final resized = img.copyResize(original, width: 512);
    final compressed = img.encodeJpg(resized, quality: 70);
    return Uint8List.fromList(compressed);
  }

  Future<String> fetchSavedLocationAndGetGuidance() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return "User not logged in.";
    }

    final doc =
        await FirebaseFirestore.instance
            .collection('locations')
            .doc(user.uid)
            .get();

    final GeoPoint geoPoint = doc.data()!['location'];
    final double latitude = geoPoint.latitude;
    final double longitude = geoPoint.longitude;

    // Format destination as string
    final String destination = "$latitude,$longitude";

    return destination;
  }

  Future<String> describeImageOnly(Uint8List imageBytes) async {
    print("Describing image only...");

    final model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: _geminiApiKey,
      generationConfig: GenerationConfig(maxOutputTokens: 512),
    );

    try {
      final response = await model.generateContent([
        Content.multi([
          TextPart(
            "You are assisting a blind person in understanding their surroundings based only on this image.\n\n"
            "Analyze the scene carefully and answer these questions clearly and briefly:\n"
            "- Is the path ahead walkable and free of major obstacles?\n"
            "- How far can the person move forward safely (estimate in meters if possible)?\n"
            "- Are there any objects, people, vehicles, or roadblocks ahead?\n"
            "- Describe the structure of the path (e.g., narrow sidewalk, open street, stairs, slope).\n"
            "- Mention if the road or area ahead curves, slopes, ends, or has intersections nearby.\n\n"
            "**Provide the description as a single short sentence with only the most necessary information. Avoid long or detailed responses. Prioritize safety and directional awareness.**",
          ),
          DataPart('image/jpeg', imageBytes),
        ]),
      ]);

      final result = response.text?.trim();
      print("Image-only response:\n$result");

      if (result == null || result.isEmpty) {
        return "Unable to describe the image.";
      }
      return result;
    } catch (e) {
      print("Gemini (image only) failed: $e");
      return "Error describing the image: $e";
    }
  }

  Future<String> getFirstDirection(String guidanceText) async {
    print("Summarizing first direction...");

    final model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: _geminiApiKey,
      generationConfig: GenerationConfig(maxOutputTokens: 256),
    );

    try {
      final response = await model.generateContent([
        Content.text(
          "You are assisting a blind person who is following walking directions.\n"
          "Given the directions below, extract and return only the *first clear and actionable instruction* that:\n"
          "- Tells exactly how far the person should walk (e.g., 'in 60 meters'),\n"
          "- States the direction they need to turn (left, right, or continue straight),\n"
          "- Mentions any nearby road names, landmarks, or intersections to help orient them.\n\n"
          "Avoid vague instructions like 'Head east' or 'Go straight'.\n"
          "Be specific and practical. Only return **one short sentence**.\n"
          "Example: 'Walk 70 meters and turn left onto Pine Street near the pharmacy.'\n\n"
          "Directions:\n$guidanceText",
        ),
      ]);

      final result = response.text?.trim();
      print("First direction response:\n$result");

      if (result == null || result.isEmpty) {
        return "Unable to extract first direction.";
      }
      return result;
    } catch (e) {
      print("Gemini (first direction) failed: $e");
      return "Error extracting direction: $e";
    }
  }

  Future<void> speak(String text) async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setPitch(1.0);
    await _flutterTts.speak(text);
  }

  Future<void> stopSpeak() async {
    print("Stopping speech...");
    try {
      await _flutterTts.stop();
    } catch (e) {
      print("Error stopping speech: $e");
    }
  }

  // Future<String?> captureDescribeSpeak() async {
  //   if (_isLooping) {
  //     _stopRequested = true;
  //     return null;
  //   }

  //   _isLooping = true;
  //   _stopRequested = false;
  //   String? lastDescription;

  //   while (!_stopRequested) {
  //     final photo = await autoCaptureImage();
  //     if (photo == null) break;

  //     final compressedBytes = await compressImage(photo);
  //     final imgDesc = await describeImageOnly(compressedBytes);

  //     final guidanceService = GuidanceService();
  //     final destination = await fetchSavedLocationAndGetGuidance();

  //     if (destination == "User not logged in.") {
  //       print("No destination available.");
  //       return "No destination found";
  //     }

  //     final directionsRaw = await guidanceService.getGuidance(destination);
  //     final firstDir = await getFirstDirection(directionsRaw);

  //     final combined = "$imgDesc. $firstDir";
  //     await speak(combined);
  //     lastDescription = combined;

  //     if (_stopRequested) break;

  //     print("Waiting 10 seconds...");
  //     for (int i = 0; i < 10; i++) {
  //       if (_stopRequested) break;
  //       await Future.delayed(Duration(seconds: 1));
  //     }
  //   }

  //   _isLooping = false;
  //   _stopRequested = false;
  //   await _cameraController?.dispose();
  //   _cameraController = null;

  //   print("Loop finished.");
  //   return lastDescription;
  // }
  Future<String?> captureDescribeSpeak() async {
    // If already looping, request stop and wait for it to finish
    if (_isLooping) {
      print("Stop requested on re-call.");
      _stopRequested = true;
      await stopSpeak(); // Immediately stop speech
      await _cameraController?.dispose(); // Dispose current camera session
      _cameraController = null;
      return null;
    }

    _isLooping = true;
    _stopRequested = false;
    String? lastDescription;

    try {
      while (!_stopRequested) {
        final photo = await autoCaptureImage();
        if (_stopRequested || photo == null) break;

        final compressedBytes = await compressImage(photo);
        if (_stopRequested) break;

        final imgDesc = await describeImageOnly(compressedBytes);
        if (_stopRequested) break;

        final guidanceService = GuidanceService();
        final destination = await fetchSavedLocationAndGetGuidance();
        if (_stopRequested || destination == "User not logged in.") break;

        final directionsRaw = await guidanceService.getGuidance(destination);
        if (_stopRequested) break;

        final firstDir = await getFirstDirection(directionsRaw);
        if (_stopRequested) break;

        final combined = "$imgDesc. $firstDir";

        if (_stopRequested) break;

        await speak(combined);
        lastDescription = combined;

        // Wait loop that can be interrupted
        for (int i = 0; i < 10; i++) {
          if (_stopRequested) break;
          await Future.delayed(Duration(seconds: 1));
        }
      }
    } catch (e) {
      print("Error in captureDescribeSpeak loop: $e");
    } finally {
      print("Cleaning up...");
      _isLooping = false;
      _stopRequested = false;
      await stopSpeak();
      await _cameraController?.dispose();
      _cameraController = null;
    }

    print("Loop finished.");
    return lastDescription;
  }

  bool get isLooping => _isLooping;
}

