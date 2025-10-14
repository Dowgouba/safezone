import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/user_service.dart';
import '../services/alert_service.dart';
import 'user_profile.dart';
import 'route_map_page.dart';

class AlerteDetailPage extends StatefulWidget {
  final String titre;
  final String message;
  final double latitude;
  final double longitude;
  final DateTime? date;
  final String? reporterId;
  final String? imageUrl;
  final String? id;

  const AlerteDetailPage({
    super.key,
    required this.titre,
    required this.message,
    required this.latitude,
    required this.longitude,
    this.date,
    this.reporterId,
    this.imageUrl,
    this.id,
  });

  @override
  State<AlerteDetailPage> createState() => _AlerteDetailPageState();
}

class _AlerteDetailPageState extends State<AlerteDetailPage> {
  late final MapController _mapController;
  // LocationService was used for external maps; internal route page handles position
  final UserService _userService = UserService();
  final AlertService _alertService = AlertService();

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Détails de l\'alerte'),
        backgroundColor: const Color.fromARGB(223, 60, 22, 231),
        actions: [
          if (widget.id != null)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Confirmer suppression'),
                    content: const Text('Supprimer cette alerte ?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
                      TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Supprimer')),
                    ],
                  ),
                );
                if (ok == true) {
                  await _alertService.deleteAlerte(widget.id!);
                  if (mounted) Navigator.pop(context);
                }
              },
            ),
        ],
      ),
      body: Column(
        children: [
          // Image de l'alerte
          if (widget.imageUrl != null && widget.imageUrl!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: Image.network(
                  widget.imageUrl!,
                  width: double.infinity,
                  height: 120,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return SizedBox(
                      height: 120,
                      child: Center(
                          child: CircularProgressIndicator(
                              value: progress.expectedTotalBytes != null
                                  ? progress.cumulativeBytesLoaded /
                                      (progress.expectedTotalBytes ?? 1)
                                  : null)),
                    );
                  },
                  errorBuilder: (context, error, stack) => SizedBox(
                    height: 220,
                    child: Center(
                        child: Text('Impossible de charger l\'image',
                            style: TextStyle(color: Colors.grey[700]))),
                  ),
                ),
              ),
            ),

          // Carte interactive
          Expanded(
            flex: 2,
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                  initialCenter:
                      LatLng(widget.latitude, widget.longitude),
                  initialZoom: 15.0),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                  subdomains: const ['a', 'b', 'c'],
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: LatLng(widget.latitude, widget.longitude),
                      width: 80,
                      height: 80,
                      child: const Icon(Icons.location_on,
                          color: Color.fromARGB(255, 23, 171, 234), size: 28),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Informations de l'alerte et bouton Google Maps
          Expanded(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.titre,
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(widget.message),
                  const SizedBox(height: 12),
                  Text(
                      'Position: (${widget.latitude.toStringAsFixed(5)}, ${widget.longitude.toStringAsFixed(5)})',
                      style: const TextStyle(color: Colors.grey)),
                  const SizedBox(height: 8),
                  Text(widget.date != null
                      ? 'Date: ${widget.date!.toLocal()}'
                      : 'Date: inconnue'),
                  const SizedBox(height: 8),

                  ElevatedButton.icon(
                    icon: const Icon(Icons.directions),
                    label: const Text('Localiser l\'alerte'),
                    style: ElevatedButton.styleFrom(
                        backgroundColor:
                            const Color.fromARGB(255, 56, 19, 208)),
                    onPressed: () async {
                      // Open internal route map page so contact can follow the reporter.
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => RouteMapPage(destLat: widget.latitude, destLng: widget.longitude),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),

                  if (widget.reporterId != null)
                    FutureBuilder<Map<String, dynamic>?>(
                      future: _userService.getUserData(widget.reporterId!),
                      builder: (context, snap) {
                        if (snap.connectionState == ConnectionState.waiting) {
                          return const SizedBox.shrink();
                        }
                        final data = snap.data;
                        if (data == null) return const Text('Utilisateur inconnu');
                        final username =
                            '${data['name'] ?? ''} ${data['surname'] ?? ''}';
                        return GestureDetector(
                          onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      UserProfilePage(uid: widget.reporterId!))),
                          child: Text('Signalé par : $username',
                              style: const TextStyle(color: Colors.blue)),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
