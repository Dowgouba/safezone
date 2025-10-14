import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/location_service.dart';

class RouteMapPage extends StatefulWidget {
  final double destLat;
  final double destLng;
  const RouteMapPage({super.key, required this.destLat, required this.destLng});

  @override
  State<RouteMapPage> createState() => _RouteMapPageState();
}

class _RouteMapPageState extends State<RouteMapPage> {
  final _mapController = MapController();
  final _locationService = LocationService();
  LatLng? _userPos;
  List<LatLng> _route = [];

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final pos = await _locationService.getCurrentPositionSafe();
    setState(() {
      if (pos != null) {
        _userPos = LatLng(pos.latitude, pos.longitude);
        _route = [ _userPos!, LatLng(widget.destLat, widget.destLng) ];
        _mapController.move(_userPos!, 13.0);
      } else {
        _route = [ LatLng(widget.destLat, widget.destLng) ];
        _mapController.move(LatLng(widget.destLat, widget.destLng), 13.0);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final dest = LatLng(widget.destLat, widget.destLng);
    final markers = <Marker>[
      Marker(point: dest, width: 40, height: 40, child: const Icon(Icons.location_on, color: Colors.red, size: 36)),
    ];
    if (_userPos != null) {
      markers.add(Marker(point: _userPos!, width: 36, height: 36, child: const Icon(Icons.person_pin_circle, color: Colors.blue, size: 34)));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Itinéraire'), backgroundColor: Colors.redAccent),
      body: FlutterMap(
        mapController: _mapController,
        options: MapOptions(initialCenter: _userPos ?? dest, initialZoom: 13.0),
        children: [
          TileLayer(urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', subdomains: const ['a','b','c']),
          MarkerLayer(markers: markers),
          if (_route.length >= 2)
            PolylineLayer(polylines: [Polyline(points: _route, color: Colors.blueAccent, strokeWidth: 4.0)]),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.redAccent,
        onPressed: () async {
          final pos = await _locationService.getCurrentPositionSafe();
          if (pos != null) {
            final p = LatLng(pos.latitude, pos.longitude);
            setState(() { _userPos = p; _route = [p, dest]; });
            _mapController.move(p, 13.0);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Position non disponible')));
          }
        },
        child: const Icon(Icons.my_location),
      ),
    );
  }
}
