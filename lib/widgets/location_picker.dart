import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:clearway/utils/top_snackbar.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

// Updated LocationPickerOverlay widget
class LocationPickerOverlay extends StatefulWidget {
  final LatLng? initialLocation;
  final Function(LatLng) onLocationSelected;
  final VoidCallback onClose;

  const LocationPickerOverlay({
    super.key,
    this.initialLocation,
    required this.onLocationSelected,
    required this.onClose,
  });

  @override
  State<LocationPickerOverlay> createState() => _LocationPickerOverlayState();
}

class _LocationPickerOverlayState extends State<LocationPickerOverlay> {
  late final MapController _mapController;
  late LatLng _currentLocation;
  bool _isLoadingCurrentLocation = false;

@override
void initState() {
  super.initState();
  _mapController = MapController();
  _currentLocation = widget.initialLocation ?? LatLng(6.9271, 79.8612);

  WidgetsBinding.instance.addPostFrameCallback((_) async {
    await Future.delayed(const Duration(milliseconds: 100));
    if (mounted) {
      _mapController.move(_currentLocation, 15.0);
    }
  });
}

    Future<void> _getCurrentLocation() async {
    if (kIsWeb) {
      _showError('Location access not supported on web platform.');
      return;
    }

    setState(() => _isLoadingCurrentLocation = true);

    try {
      // Check if location services are enabled
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showError('Location services are disabled. Please enable them in settings.');
        return;
      }

      // Check and request location permission using permission_handler
      PermissionStatus permission = await Permission.location.status;
      
      if (permission.isDenied) {
        permission = await Permission.location.request();
      }

      if (permission.isDenied) {
        _showError('Location permission denied. Please grant permission to use this feature.');
        return;
      }

      if (permission.isPermanentlyDenied) {
        _showError('Location permission permanently denied. Please enable it in app settings.');
        // Optionally open app settings
        await openAppSettings();
        return;
      }

      // Get current position with timeout and accuracy settings
      final position = await Geolocator.getCurrentPosition();

      final newLocation = LatLng(position.latitude, position.longitude);
      
      if (mounted) {
        setState(() {
          _currentLocation = newLocation;
        });
        _mapController.move(newLocation, 15.0);
      }
    } catch (e) {
      if (e.toString().contains('TimeoutException')) {
        _showError('Location request timed out. Please try again.');
      } else {
        _showError('Error getting location: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingCurrentLocation = false);
      }
    }
  }

  void _showError(String message) {
  showTopSnackBar(context, message , type: TopSnackBarType.error);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black54, // Semi-transparent background
      child: SafeArea(
        child: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            width: MediaQuery.of(context).size.width * 0.9,
            height: MediaQuery.of(context).size.height * 0.75,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        'Select Location',
                        style: GoogleFonts.urbanist(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: widget.onClose,
                      ),
                    ],
                  ),
                ),

                // Map
                Expanded(
                  child: ClipRRect(
                    child: FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        onTap: (_, point) {
                          setState(() {
                            _currentLocation = point;
                          });
                        },
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.example.app',
                        ),
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: _currentLocation,
                              width: 40,
                              height: 40,
                              alignment: Alignment.center,
                              child: const Icon(
                                Icons.location_pin,
                                size: 40,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Bottom Buttons
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _isLoadingCurrentLocation ? null : _getCurrentLocation,
                          icon: _isLoadingCurrentLocation
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.my_location),
                          label: Text(
                            'Use Current Location',
                            style: GoogleFonts.urbanist(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            widget.onLocationSelected(_currentLocation);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1E232C),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: Text(
                            'Set Location',
                            style: GoogleFonts.urbanist(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
