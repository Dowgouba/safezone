import 'package:cloud_firestore/cloud_firestore.dart';

class AlertModel {
  final String titre;
  final String message;
  final double latitude;
  final double longitude;
  final DateTime? date;
  final String? reporterId;

  AlertModel({
    required this.titre,
    required this.message,
    required this.latitude,
    required this.longitude,
    this.date,
    this.reporterId,
  });

  factory AlertModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    DateTime? date;
    if (data['date'] != null) {
      final raw = data['date'];
      if (raw is Timestamp) date = raw.toDate();
      if (raw is DateTime) date = raw;
    }
    final latitude = (data['latitude'] is num) ? data['latitude'].toDouble() : double.tryParse(data['latitude'].toString()) ?? 0.0;
    final longitude = (data['longitude'] is num) ? data['longitude'].toDouble() : double.tryParse(data['longitude'].toString()) ?? 0.0;

    return AlertModel(
      titre: data['titre'] ?? 'Sans titre',
      message: data['message'] ?? '',
      latitude: latitude,
      longitude: longitude,
      date: date,
      reporterId: data['reporterId'],
    );
  }
}
