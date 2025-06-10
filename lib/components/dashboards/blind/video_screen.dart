import 'package:clearway/components/videoCallWidget.dart';
import 'package:clearway/services/firestore.dart';
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
  final FirestoreService _firestoreService = FirestoreService();
  String _uid = '00';
  bool _isBlind = false;

  @override
  void initState() {
    super.initState();

    Future.delayed(const Duration(milliseconds: 300), () {
      // Describe the screen
      _imageDescriptionService.speak(TtsMessages.videoCallScreen);
    });
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    String uid = await _firestoreService.getCurrentUserID() ?? '00';
    bool isBlind = await _firestoreService.isUserBlind(uid);
    if (mounted) {
      setState(() {
        _uid = uid;
        _isBlind = isBlind;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Video Call'),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Blind Video call Screen',
              style: TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 20),
            VideoCallWidget(),
          ],
        ),
      ),
    );
  }
}
