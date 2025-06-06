import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:clearway/services/imagedescription.dart';
import 'package:clearway/constants/tts_messages.dart';

class AiAssistanceScreen extends ConsumerStatefulWidget {
  const AiAssistanceScreen({super.key});

  @override
  ConsumerState<AiAssistanceScreen> createState() => _AiAssistanceScreenState();
}

class _AiAssistanceScreenState extends ConsumerState<AiAssistanceScreen> {
    final ImageDescriptionService _imageDescriptionService = ImageDescriptionService();

  @override
  void initState() {
    super.initState();

    Future.delayed(const Duration(milliseconds: 300), () {
      // Describe the screen
      _imageDescriptionService.speak(TtsMessages.aiAssistanceScreen);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Assistance'),
        automaticallyImplyLeading: false,
      ),
      body: const Center(
        child: Text(
          'AI assistance screen',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
