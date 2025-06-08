import 'package:clearway/components/videoCallWidget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:clearway/widgets/draggable_map_popup.dart';

class GpsTrackingScreen extends ConsumerStatefulWidget {
  const GpsTrackingScreen({super.key});

  @override
  ConsumerState<GpsTrackingScreen> createState() => _GpsTrackingScreenState();
}

class _GpsTrackingScreenState extends ConsumerState<GpsTrackingScreen> {
  bool _isMapVisible = false;

  LatLng _currentLocation = LatLng(6.9271, 79.8612);
  final LatLng _destinationLocation = LatLng(6.9319, 79.8478);

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
      _updateCurrentLocation(LatLng(6.9285, 79.8570));
    });
  }

  @override
  Widget build(BuildContext context) {
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
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.gps_fixed, size: 80, color: Colors.blue),
                SizedBox(height: 20),
                Text(
                  'GPS Tracking Active',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                Text(
                  'Tap the map icon to view navigation',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
            ),
          ),
          if (_isMapVisible)
            DraggableMapPopup(
              currentLocation: _currentLocation,
              destinationLocation: _destinationLocation,
              onClose: _toggleMap,
            ),
        ],
      ),
    );
  }
}
