import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

class LocationService {
  // Vérifie si la localisation est activée et les permissions sont accordées
  Future<bool> checkPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return false;
    }
    if (permission == LocationPermission.deniedForever) return false;

    return true;
  }

  // Récupère la position actuelle de l'utilisateur
  Future<Position?> getCurrentPositionSafe() async {
    try {
      final hasPermission = await checkPermission();
      if (!hasPermission) return null;

      return await Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.high)
          .timeout(const Duration(seconds: 10));
    } catch (_) {
      return null;
    }
  }

  // Ouvre Google Maps avec l'origine (utilisateur) et la destination (alerte)
  Future<void> openGoogleMaps(double destLat, double destLng) async {
    final pos = await getCurrentPositionSafe();
    final origin = pos != null ? '${pos.latitude},${pos.longitude}' : '';
    final dest = '$destLat,$destLng';
    final uri = origin.isNotEmpty
        ? Uri.parse('https://www.google.com/maps/dir/$origin/$dest')
        : Uri.parse('https://www.google.com/maps/search/?api=1&query=$dest');

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      throw 'Impossible d\'ouvrir Google Maps';
    }
  }
}
