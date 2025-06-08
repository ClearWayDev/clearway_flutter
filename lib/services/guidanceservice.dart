import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

class GuidanceService {
  final String _googleApiKey = 'AIzaSyC54BC8i82O4rPnSTp7j2h36kjteHbUmZ0';

  Future<String> getGuidance(String destinationPlaceName) async {
    try {
      final hasPermission = await _checkLocationPermission();
      if (!hasPermission) return "Location permission denied.";

      final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      final origin = "${position.latitude},${position.longitude}";
      final destination = Uri.encodeComponent(destinationPlaceName);

      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/directions/json'
        '?origin=$origin'
        '&destination=$destination'
        '&mode=walking'
        '&key=$_googleApiKey',
      );

      final response = await http.get(url);
      if (response.statusCode != 200) {
        return "Failed to fetch directions: HTTP ${response.statusCode}";
      }

      final data = json.decode(response.body);
      if (data['status'] != 'OK') {
        return "Directions API error: ${data['status']}";
      }

      final steps = data['routes'][0]['legs'][0]['steps'];
      final instructions = steps.map<String>((step) {
        return _stripHtmlTags(step['html_instructions']);
      }).join(', ');

      return "Directions to $destinationPlaceName: $instructions";
    } catch (e) {
      return "Error fetching guidance: $e";
    }
  }

  Future<bool> _checkLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();
    }

    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  String _stripHtmlTags(String htmlText) {
    return htmlText.replaceAll(RegExp(r'<[^>]*>'), '');
  }
}
