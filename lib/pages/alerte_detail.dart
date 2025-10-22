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
  final UserService _userService = UserService();
  final AlertService _alertService = AlertService();

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  Future<void> _deleteAlert() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('🗑️ Confirmer la suppression'),
        content: const Text('Voulez-vous vraiment supprimer cette alerte ?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler')),
          ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Supprimer')),
        ],
      ),
    );

    if (ok == true) {
      await _alertService.deleteAlerte(widget.id!);
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final position = LatLng(widget.latitude, widget.longitude);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Détails de l'alerte"),
        backgroundColor: Colors.blue,
        actions: [
          if (widget.id != null)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.white),
              onPressed: _deleteAlert,
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Image
            if (widget.imageUrl != null && widget.imageUrl!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    widget.imageUrl!,
                    width: double.infinity,
                    height: 180,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, progress) =>
                        progress == null
                            ? child
                            : const SizedBox(
                                height: 180,
                                child: Center(
                                    child: CircularProgressIndicator())),
                    errorBuilder: (context, error, stack) => Container(
                      height: 180,
                      color: Colors.grey.shade200,
                      child: const Center(
                          child: Text('Impossible de charger l’image')),
                    ),
                  ),
                ),
              ),

            // Carte
            Container(
              height: 250,
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: position,
                    initialZoom: 14.5,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                      subdomains: const ['a', 'b', 'c'],
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: position,
                          width: 50,
                          height: 50,
                          child: const Icon(Icons.location_on,
                              color: Colors.red, size: 36),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Détails
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.titre,
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text(widget.message,
                      style: const TextStyle(fontSize: 16, height: 1.4)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: Colors.grey),
                      const SizedBox(width: 5),
                      Text(
                          "(${widget.latitude.toStringAsFixed(5)}, ${widget.longitude.toStringAsFixed(5)})",
                          style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.access_time, color: Colors.grey),
                      const SizedBox(width: 5),
                      Text(
                        widget.date != null
                            ? widget.date!.toLocal().toString()
                            : 'Date inconnue',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Bouton itinéraire
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.directions),
                      label: const Text('Itinéraire vers le lieu'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            const Color.fromARGB(255, 56, 19, 208),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => RouteMapPage(
                                destLat: widget.latitude,
                                destLng: widget.longitude),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Reporter
                  if (widget.reporterId != null)
                    FutureBuilder<Map<String, dynamic>?>(
                      future: _userService.getUserData(widget.reporterId!),
                      builder: (context, snap) {
                        if (snap.connectionState ==
                            ConnectionState.waiting) {
                          return const SizedBox(
                              height: 20,
                              child: LinearProgressIndicator(minHeight: 2));
                        }
                        final data = snap.data;
                        if (data == null) {
                          return const Text('Signalé par : Inconnu',
                              style: TextStyle(color: Colors.grey));
                        }
                        final username =
                            '${data['name'] ?? ''} ${data['surname'] ?? ''}';
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => UserProfilePage(
                                    uid: widget.reporterId!),
                              ),
                            );
                          },
                          child: Text(
                            'Signalé par : $username',
                            style: const TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.w500),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
