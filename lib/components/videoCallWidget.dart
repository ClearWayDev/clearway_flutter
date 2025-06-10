import 'package:clearway/components/backendUrlWidget.dart';
import 'package:clearway/components/triggercall.dart';
import 'package:clearway/services/firestore.dart';
import 'package:clearway/services/websocket.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart'; // Ensure this package is added to pubspec.yaml
import '../services/webrtc.dart';
import '../providers/user_state.dart';
import '../models/user.dart';

class VideoCallWidget extends StatefulWidget {
  VideoCallWidget({super.key});

  @override
  _VideoCallWidgetState createState() => _VideoCallWidgetState();
}

class _VideoCallWidgetState extends State<VideoCallWidget> {
  late RTCVideoRenderer _localRenderer;
  late RTCVideoRenderer _remoteRenderer;
  late RTCPeerConnection _peerConnection;
  late MediaStream _localStream;
  final WebSocketService _webSocketService = WebSocketService.getInstance();
  final container = ProviderContainer();
  final FirestoreService _firestoreService = FirestoreService();

  late final String uid;
  late final bool isBlind;
  final List<RTCIceCandidate> _pendingCandidates = [];

  var virginOffer = true;

  @override
  void initState() {
    super.initState();
    initialize();
  }

  Future<void> initialize() async {
    _localRenderer = RTCVideoRenderer();
    _remoteRenderer = RTCVideoRenderer();
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();
    await fetchUserData(); // 1. Fetch user data first
    await _createPeerConnection(); // 2. Then create peer connection
    if (isBlind) {
      // 3. Now safe to create offer
      await createOffer();
    }
    _setupWebSocketListeners();
    setState(() {});
  }

  Future<void> fetchUserData() async {
    uid = await _firestoreService.getCurrentUserID() ?? '00';
    isBlind = await _firestoreService.isUserBlind(uid);
    print("User ID: $uid, Is Blind: $isBlind");
  }

  Future<MediaStream> _getUserMedia() async {
    print("Printing the fk");
    print(isBlind);
    print(uid);
    final needVideo = isBlind ? {'facingMode': 'environment'} : false;
    final mediaConstraints = {'audio': true, 'video': needVideo};
    _localStream = await navigator.mediaDevices.getUserMedia(mediaConstraints);
    _localRenderer.srcObject = _localStream;
    return _localStream;
  }

  Future<void> _createPeerConnection() async {
    _peerConnection = await createPeerConnection({
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
      ],
      'sdpSemantics': 'unified-plan',
    });
    final localStream = await _getUserMedia();
    for (var track in _localStream.getTracks()) {
      _peerConnection.addTrack(track, localStream);
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

  Future<void> createOffer() async {
    if (isBlind) {
      RTCSessionDescription offer = await _peerConnection.createOffer();
      await _peerConnection.setLocalDescription(offer);

      _webSocketService.sendMessage('offer', {
        'sdp': offer.sdp,
        'type': offer.type,
        'userType': "blind",
        'uid': uid,
      });
    }
  }

  Future<void> setRemoteDescription(RTCSessionDescription description) async {
    print('Setting remote description with answer: $description');
    await _peerConnection.setRemoteDescription(description);
    print('Remote description set. Adding any queued ICE candidates...');
    for (final candidate in _pendingCandidates) {
      try {
        await _peerConnection.addCandidate(candidate);
        print('Added queued ICE candidate: ${candidate.candidate}');
      } catch (e) {
        print('Error adding queued ICE candidate: $e');
      }
    }
    _pendingCandidates.clear();
  }

  Future<void> addIceCandidate(RTCIceCandidate candidate) async {
    if (_peerConnection.signalingState ==
        RTCSignalingState.RTCSignalingStateClosed) {
      print('Cannot add ICE candidate: PeerConnection is closed.');
      return;
    }
    final remoteDescription = await _peerConnection.getRemoteDescription();
    if (remoteDescription == null) {
      _pendingCandidates.add(candidate);
      print('Queued ICE candidate because remoteDescription is null');
      return;
    }
    try {
      await _peerConnection.addCandidate(candidate);
      print('Added ICE candidate immediately: ${candidate.candidate}');
    } catch (e) {
      print('Error adding ICE candidate: $e');
    }
  }

  void _setupWebSocketListeners() {
    _webSocketService.socket.on('offer', (data) async {
      print('Received offer: $data');
      if (!virginOffer) return;
      virginOffer = false;
      //r  TriggerCall.handleIncomingCall(uid, "${data['uid']}");
      final description = RTCSessionDescription(data['sdp'], data['type']);
      print('Setting remote description with offer: $description');
      await setRemoteDescription(description);

      RTCSessionDescription answer = await _peerConnection.createAnswer();
      await _peerConnection.setLocalDescription(answer);

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
      if (_peerConnection.signalingState ==
          RTCSignalingState.RTCSignalingStateClosed) {
        print('PeerConnection is closed, ignoring ICE candidate.');
        return;
      }
      final candidateMap = data['candidate'];
      final candidate = RTCIceCandidate(
        candidateMap['candidate'],
        candidateMap['sdpMid'],
        candidateMap['sdpMLineIndex'],
      );
      await addIceCandidate(candidate);
    });
  }

  void disconnect() async {
    //await _localStream.dispose();
    //await _peerConnection.close();
    // _localRenderer.dispose();
    // _remoteRenderer.dispose();
    virginOffer = true;
  }

  bool isConnectionEstablished() {
    return _peerConnection.connectionState ==
        RTCPeerConnectionState.RTCPeerConnectionStateConnected;
  }

  RTCVideoRenderer get localRenderer => _localRenderer;
  RTCVideoRenderer get remoteRenderer => _remoteRenderer;

  @override
  void dispose() {
    disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: RTCVideoView(_remoteRenderer));
  }
}
