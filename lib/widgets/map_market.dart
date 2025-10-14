import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapMarker extends StatelessWidget {
  final VoidCallback? onTap;
  final Color color;
  final double size;

  const MapMarker({
    super.key,
    this.onTap,
    this.color = Colors.red,
    this.size = 36,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Icon(Icons.location_on, color: color, size: size),
    );
  }
}

/// Helper that builds a flutter_map [Marker] from latitude/longitude and a
/// [MapMarker] widget. Use this in map pages instead of trying to insert a
/// Marker widget directly into widget tree.
Marker markerFromLatLng(LatLng position, {required MapMarker child}) {
  return Marker(
    point: position,
    width: child.size,
    height: child.size,
    child: child,
  );
}
