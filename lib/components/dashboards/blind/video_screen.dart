import 'package:clearway/components/videoCallWidget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:clearway/services/imagedescription.dart';
import 'package:clearway/constants/tts_messages.dart';

class BlindVideoCallScreen extends ConsumerStatefulWidget {
  const BlindVideoCallScreen({super.key});

  @override
  ConsumerState<BlindVideoCallScreen> createState() =>
      _BlindVideoCallScreenState();
}

class _BlindVideoCallScreenState extends ConsumerState<BlindVideoCallScreen> {
  final ImageDescriptionService _imageDescriptionService =
      ImageDescriptionService();

  @override
  void initState() {
    super.initState();

    Future.delayed(const Duration(milliseconds: 300), () {
      // Describe the screen
      _imageDescriptionService.speak(TtsMessages.videoCallScreen);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Video Call'),
        automaticallyImplyLeading: false,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Blind Video call Screen', style: TextStyle(fontSize: 24)),
            SizedBox(height: 20),
            VideoCallWidget(),
          ],
        ),
      ),
    );
  }
}
