import 'package:clearway/components/backendUrlWidget.dart';
import 'package:clearway/services/websocket.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart'; // Ensure this package is added to pubspec.yaml
// Ensure this file exists and has the required provider
import '../services/webrtc.dart'; // Ensure this file exists and defines WebRTCService

class VideoCallWidget extends StatefulWidget {
  const VideoCallWidget({super.key});

  @override
  _VideoCallWidgetState createState() => _VideoCallWidgetState();
}

class _VideoCallWidgetState extends State<VideoCallWidget> {
  late WebRTCService _webrtcService;
  final WebSocketService _webSocketService = WebSocketService();

  @override
  void initState() {
    super.initState();
    _webrtcService = WebRTCService(_webSocketService);
    _initializeWebRTC();
  }

  Future<void> _initializeWebRTC() async {
    await _webrtcService.initialize();
    setState(() {});
  }

  @override
  void dispose() {
    _webrtcService.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Video call')),
      body: Column(
        children: [
          Expanded(child: BackendUrlWidget()),
          Expanded(
            child: Column(
              children: [
                const Text('Local', style: TextStyle(fontSize: 16)),
                Expanded(child: RTCVideoView(_webrtcService.localRenderer)),
              ],
            ),
          ),
          Expanded(
            child: Column(
              children: [
                const Text('Remote', style: TextStyle(fontSize: 16)),
                Expanded(child: RTCVideoView(_webrtcService.remoteRenderer)),
              ],
            ),
          ),

          ElevatedButton(
            onPressed: () async {
              await _webrtcService.createOffer();
              // Send offer to the other peer (via signaling server)
            },
            child: const Text('Start Call'),
          ),
        ],
      ),
    );
  }
}
