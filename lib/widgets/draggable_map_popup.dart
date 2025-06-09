// lib/widgets/draggable_map_popup.dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';

class DraggableMapPopup extends StatefulWidget {
  final LatLng currentLocation;
  final LatLng destinationLocation;
  final VoidCallback onClose;

  const DraggableMapPopup({
    super.key,
    required this.currentLocation,
    required this.destinationLocation,
    required this.onClose,
  });

  @override
  State<DraggableMapPopup> createState() => _DraggableMapPopupState();
}

class _DraggableMapPopupState extends State<DraggableMapPopup> {
  Offset _mapOffset = Offset(20, 100);

  List<LatLng> _generateRoutePoints(LatLng start, LatLng end) {
    List<LatLng> points = [];
    int segments = 10;
    for (int i = 0; i <= segments; i++) {
      double ratio = i / segments;
      double lat = start.latitude + (end.latitude - start.latitude) * ratio;
      double lng = start.longitude + (end.longitude - start.longitude) * ratio;
      points.add(LatLng(lat, lng));
    }
    return points;
  }

  double _calculateDistance() {
    const Distance distance = Distance();
    return distance.as(LengthUnit.Kilometer, widget.currentLocation, widget.destinationLocation);
  }

  @override
  Widget build(BuildContext context) {
    final routePoints = _generateRoutePoints(widget.currentLocation, widget.destinationLocation);

    final markers = [
      Marker(
        point: widget.currentLocation,
        width: 40,
        height: 40,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.blue,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
          ),
          child: Icon(Icons.my_location, color: Colors.white, size: 20),
        ),
      ),
      Marker(
        point: widget.destinationLocation,
        width: 40,
        height: 40,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.red,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
          ),
          child: Icon(Icons.location_on, color: Colors.white, size: 20),
        ),
      ),
    ];

    return Positioned(
      left: _mapOffset.dx,
      top: _mapOffset.dy,
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            _mapOffset += details.delta;
          });
        },
        child: Material(
          elevation: 12,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.6,
            height: MediaQuery.of(context).size.height * 0.5,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                children: [
                  FlutterMap(
                    options: MapOptions(
                      initialCenter: widget.currentLocation,
                      initialZoom: 14.0,
                      minZoom: 10.0,
                      maxZoom: 18.0,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                        subdomains: const ['a', 'b', 'c'],
                        tileProvider: CancellableNetworkTileProvider(),
                        userAgentPackageName: 'com.example.app',
                      ),
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: routePoints,
                            strokeWidth: 4.0,
                            color: Colors.blue.withOpacity(0.8),
                            pattern: StrokePattern.dashed(segments: [5.0, 5.0]),
                          ),
                        ],
                      ),
                      MarkerLayer(markers: markers),
                    ],
                  ),
                  Positioned(
                    top: 8,
                    left: 8,
                    right: 8,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: const [
                          Text('Navigation', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                          Icon(Icons.navigation, color: Colors.white, size: 16),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 8,
                    left: 8,
                    right: 8,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.route, size: 14, color: Colors.blue),
                              SizedBox(width: 4),
                              Text('${_calculateDistance().toStringAsFixed(1)} km', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                            ],
                          ),
                          Row(
                            children: [
                              Icon(Icons.access_time, size: 14, color: Colors.green),
                              SizedBox(width: 4),
                              Text('${(_calculateDistance() * 2).toInt()} min', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: widget.onClose,
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(color: Colors.red.withOpacity(0.8), shape: BoxShape.circle),
                        child: const Icon(Icons.close, color: Colors.white, size: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
