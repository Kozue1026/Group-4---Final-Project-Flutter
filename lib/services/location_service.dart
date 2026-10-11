import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

/// Location: distance display + open externally in Google Maps.
class LocationService {
  /// Returns distance in km, or null if permission denied / unavailable.
  static Future<double?> distanceKmTo(
      double lat, double lng) async {
    final status = await Permission.locationWhenInUse.request();
    if (!status.isGranted) return null;
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) return null;
    try {
      final pos = await Geolocator.getCurrentPosition(
          locationSettings:
              const LocationSettings(accuracy: LocationAccuracy.medium));
      final meters = Geolocator.distanceBetween(
          pos.latitude, pos.longitude, lat, lng);
      return meters / 1000.0;
    } catch (_) {
      return null;
    }
  }

  static Future<void> openInMaps(double lat, double lng, String label) async {
    final uri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$lat,$lng(${Uri.encodeComponent(label)})');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      throw Exception('Could not open Maps.');
    }
  }
}
