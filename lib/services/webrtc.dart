import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'websocket.dart'; // Import the WebSocketService

class WebRTCService {
  late RTCVideoRenderer _localRenderer;
  late RTCVideoRenderer _remoteRenderer;
  late RTCPeerConnection _peerConnection;
  late MediaStream _localStream;
  final WebSocketService _webSocketService;

  WebRTCService(this._webSocketService);

  // Initialize the renderers, peer connection, and WebSocket
  Future<void> initialize() async {
    _localRenderer = RTCVideoRenderer();
    _remoteRenderer = RTCVideoRenderer();
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();
    await _getUserMedia();
    await _createPeerConnection();
    _setupWebSocketListeners();
  }

  // Get media stream (camera and microphone)
  Future<void> _getUserMedia() async {
    final mediaConstraints = {
      'audio': true,
      'video': {'facingMode': 'user'},
    };
    _localStream = await navigator.mediaDevices.getUserMedia(mediaConstraints);
    _localRenderer.srcObject = _localStream;
  }

  // Create peer connection
  Future<void> _createPeerConnection() async {
    _peerConnection = await createPeerConnection({
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
      ],
      'sdpSemantics': 'unified-plan',
    });

    for (var track in _localStream.getTracks()) {
      _peerConnection.addTrack(track, _localStream);
    }

    _peerConnection.onIceCandidate = (candidate) {
      print('Sending ICE Candidate: ${candidate.candidate}');
      _webSocketService.sendMessage('ice-candidate', {
        'candidate': candidate.toMap(),
      });
    };

    _peerConnection.onTrack = (event) {
      print('Received remote track');
      if (event.streams.isNotEmpty) {
        _remoteRenderer.srcObject = event.streams[0];
      }
    };
  }

  // Create an offer to start communication
  Future<void> createOffer() async {
    RTCSessionDescription offer = await _peerConnection.createOffer();
    await _peerConnection.setLocalDescription(offer);

    // Send the offer to the WebSocket server
    _webSocketService.sendMessage('offer', {
      'sdp': offer.sdp,
      'type': offer.type,
    });
  }

  // Set remote description
  Future<void> setRemoteDescription(RTCSessionDescription description) async {
    await _peerConnection.setRemoteDescription(description);
  }

  // Add ICE candidate to the peer connection
  Future<void> addIceCandidate(RTCIceCandidate candidate) async {
    await _peerConnection.addCandidate(candidate);
  }

  // Set up WebSocket listeners for signaling
  void _setupWebSocketListeners() {
    _webSocketService.socket.on('offer', (data) async {
      print('Received offer: $data');
      final description = RTCSessionDescription(data['sdp'], data['type']);
      await setRemoteDescription(description);

      // Create an answer in response to the offer
      RTCSessionDescription answer = await _peerConnection.createAnswer();
      await _peerConnection.setLocalDescription(answer);

      // Send the answer back to the WebSocket server
      _webSocketService.sendMessage('answer', {
        'sdp': answer.sdp,
        'type': answer.type,
      });
    });

    _webSocketService.socket.on('answer', (data) async {
      print('Received answer: $data');
      final description = RTCSessionDescription(data['sdp'], data['type']);
      await setRemoteDescription(description);
    });

    _webSocketService.socket.on('ice-candidate', (data) async {
      print('Received ICE Candidate: $data');

      final candidateMap =
          data['candidate']; // this is likely the real Map you want

      final candidate = RTCIceCandidate(
        candidateMap['candidate'],
        candidateMap['sdpMid'],
        candidateMap['sdpMLineIndex'],
      );

      await addIceCandidate(candidate);
    });
  }

  // Dispose the resources
  void disconnect() async {
    await _localStream.dispose();
    await _peerConnection.close();
    _localRenderer.dispose();
    _remoteRenderer.dispose();
  }

  // Getters for the renderers
  RTCVideoRenderer get localRenderer => _localRenderer;
  RTCVideoRenderer get remoteRenderer => _remoteRenderer;
}
