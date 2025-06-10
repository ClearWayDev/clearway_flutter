import 'package:clearway/components/videoCallWidget.dart';
import 'package:clearway/services/firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:clearway/widgets/draggable_map_popup.dart';
import 'package:clearway/providers/user_state.dart';

class GpsTrackingScreen extends ConsumerStatefulWidget {
  const GpsTrackingScreen({super.key});

  @override
  ConsumerState<GpsTrackingScreen> createState() => _GpsTrackingScreenState();
}

class _GpsTrackingScreenState extends ConsumerState<GpsTrackingScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  bool _isMapVisible = false;
  LatLng _currentLocation = LatLng(6.9271, 79.8612);
  final LatLng _destinationLocation = LatLng(6.9319, 79.8478);

  String _uid = '00';
  bool _isBlind = false;

  void _toggleMap() {
    setState(() {
      _isMapVisible = !_isMapVisible;
    });
  }

  void _updateCurrentLocation(LatLng newLocation) {
    setState(() {
      _currentLocation = newLocation;
    });
  }

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(seconds: 3), () {
      if (mounted) {
        _updateCurrentLocation(LatLng(6.9285, 79.8570));
      }
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
    final token = ref.watch(userProvider)?.fcmToken;
    return Scaffold(
      appBar: AppBar(
        title: const Text('GPS Tracking'),
        actions: [
          IconButton(
            icon: Icon(_isMapVisible ? Icons.close : Icons.map),
            onPressed: _toggleMap,
          ),
        ],
      ),
      body: Stack(
        children: [
          Center(child: Column(children: [Expanded(child: VideoCallWidget())])),
        ],
      ),
    );
  }
}
