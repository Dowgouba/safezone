import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../services/alert_service.dart';
import '../models/alert_model.dart';
import 'alerte_detail.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final MapController _mapController = MapController();
  LatLng? _userPosition;
  List<LatLng> _route = [];

  final AlertService _alertService = AlertService();

  @override
  void initState() {
    super.initState();
    _getUserPosition();
  }

  Future<void> _getUserPosition() async {
    try {
      final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      setState(() => _userPosition = LatLng(pos.latitude, pos.longitude));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Impossible d'obtenir la position: $e")),
      );
    }
  }

  // route handling moved to in-app RouteMapPage; markers open detail page

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<AlertModel>>(
      stream: _alertService.streamAlertes(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final alertes = snapshot.data ?? [];
        if (alertes.isEmpty) {
          return const Center(child: Text("Aucune alerte à afficher sur la carte."));
        }

        final markers = alertes.map((alerte) {
          final point = LatLng(alerte.latitude, alerte.longitude);
          return Marker(
            point: point,
            width: 40,
            height: 40,
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AlerteDetailPage(
                      titre: alerte.titre,
                      message: alerte.message,
                      latitude: alerte.latitude,
                      longitude: alerte.longitude,
                      date: alerte.date,
                      reporterId: alerte.reporterId,
                      imageUrl: alerte.imageUrl,
                      id: alerte.id,
                    ),
                  ),
                );
              },
              child: const Icon(Icons.location_on, color: Colors.red, size: 36),
            ),
          );
        }).toList();

        // Ajouter la position utilisateur si disponible
        if (_userPosition != null) {
          markers.add(
            Marker(
              point: _userPosition!,
              width: 36,
              height: 36,
              child: const Icon(Icons.person_pin_circle,
                  color: Colors.blue, size: 36),
            ),
          );
        }

        return FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _userPosition ?? markers.first.point,
            initialZoom: 13.0,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
              subdomains: const ['a', 'b', 'c'],
            ),
            MarkerLayer(markers: markers),
            if (_route.isNotEmpty)
              PolylineLayer(
                polylines: [Polyline(points: _route, strokeWidth: 4.0, color: Colors.blueAccent)],
              ),
          ],
        );
      },
    );
  }
}
