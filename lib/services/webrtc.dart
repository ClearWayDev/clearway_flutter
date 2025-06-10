import 'dart:convert';

import 'package:clearway/components/triggercall.dart';
import 'package:clearway/models/user.dart';
import 'package:clearway/providers/user_state.dart';
import 'package:clearway/services/firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'websocket.dart'; // Import the WebSocketService

class WebRTCService {
  late RTCVideoRenderer _localRenderer;
  late RTCVideoRenderer _remoteRenderer;
  late RTCPeerConnection _peerConnection;
  late MediaStream _localStream;
  final WebSocketService _webSocketService;
  final container = ProviderContainer();
  final FirestoreService _firestoreService = FirestoreService();
  var virginOffer = true;
  final String uid;
  final bool isBlind;
  final List<RTCIceCandidate> _pendingCandidates = [];

  WebRTCService(this._webSocketService, this.uid, this.isBlind);

  // Initialize the renderers, peer connection, and WebSocket
  Future<void> initialize() async {
    _localRenderer = RTCVideoRenderer();
    _remoteRenderer = RTCVideoRenderer();
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();
    await _createPeerConnection();
    _setupWebSocketListeners();
  }

  // Get media stream (camera and microphone)
  Future<MediaStream> _getUserMedia() async {
    final needVideo = !isBlind ? false : {'facingMode': 'environment'};

    final mediaConstraints = {'audio': true, 'video': needVideo};
    _localStream = await navigator.mediaDevices.getUserMedia(mediaConstraints);

    return _localStream;
  }

  // Create peer connection
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
        // Filter only video tracks
        final audioTracks = event.streams[0].getAudioTracks();
        if (audioTracks.isNotEmpty) {
          _remoteRenderer.srcObject = event.streams[0];
        }
      }
    };
  }

  // Create an offer to start communication
  Future<void> createOffer() async {
    if (isBlind) {
      {
        RTCSessionDescription offer = await _peerConnection.createOffer();
        await _peerConnection.setLocalDescription(offer);

        // Send the offer to the WebSocket server
        _webSocketService.sendMessage('offer', {
          'sdp': offer.sdp,
          'type': offer.type,
          'userType': "blind",
          'uid': uid,
        });
      }
    }
  }

  // Set remote description
  Future<void> setRemoteDescription(RTCSessionDescription description) async {
    await _peerConnection.setRemoteDescription(description);
    // Add any queued ICE candidates now that remote description is set
    for (final candidate in _pendingCandidates) {
      await _peerConnection.addCandidate(candidate);
    }
    _pendingCandidates.clear();
  }

  // Add ICE candidate to the peer connection
  Future<void> addIceCandidate(RTCIceCandidate candidate) async {
    if (_peerConnection.signalingState ==
        RTCSignalingState.RTCSignalingStateClosed) {
      print('Cannot add ICE candidate: PeerConnection is closed.');
      return;
    }
    // If remote description is not set, queue the candidate
    final remoteDescription = await _peerConnection.getRemoteDescription();
    if (remoteDescription == null) {
      _pendingCandidates.add(candidate);
      print('Queued ICE candidate because remoteDescription is null');
      return;
    }
    await _peerConnection.addCandidate(candidate);
  }

  // Set up WebSocket listeners for signaling
  void _setupWebSocketListeners() {
    _webSocketService.socket.on('offer', (data) async {
      String uid = await _firestoreService.getCurrentUserID() ?? '00';
      bool isBlind = await _firestoreService.isUserBlind(uid);
      if (!isBlind) {
        print('Received offer: $data');

        if (!virginOffer) return;
        virginOffer = false;
        TriggerCall.handleIncomingCall(uid, "${data['uid']}");
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
        /* } 
        else {
          virginOffer = true;
        }
        */
      }
    });

    _webSocketService.socket.on('answer', (data) async {
      String uid = await _firestoreService.getCurrentUserID() ?? '00';
      bool isBlind = await _firestoreService.isUserBlind(uid);
      if (!isBlind) {
        return;
      }
      // Handle the answer received from the volunteer
      // This is the answer to the offer we sent earlier
      if (data['userType'] != "blind") return; // Ignore if not for blind user
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
    // _localStream.getTracks().forEach((track) => track.stop());
    await _localStream.dispose();
    await _peerConnection.close();
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    virginOffer = true; // Reset for future calls
  }

  bool isConnectionEstablished() {
    return _peerConnection.connectionState ==
        RTCPeerConnectionState.RTCPeerConnectionStateConnected;
  }

  // Getters for the renderers
  RTCVideoRenderer get localRenderer => _localRenderer;
  RTCVideoRenderer get remoteRenderer => _remoteRenderer;
}
