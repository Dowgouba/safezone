import 'package:cloud_firestore/cloud_firestore.dart';

class AlertModel {
  final String id;
  final String titre;
  final String message;
  final double latitude;
  final double longitude;
  final DateTime? date;
  final String? reporterId;
  final String? imageUrl;
  final double? accuracy;

  AlertModel({
    required this.id,
    required this.titre,
    required this.message,
    required this.latitude,
    required this.longitude,
    this.date,
    this.reporterId,
    this.imageUrl,
    this.accuracy,
  });

  factory AlertModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    // handle Firestore Timestamp or DateTime
    DateTime? parsedDate;
    final dateField = data['date'];
    if (dateField is Timestamp) {
      parsedDate = dateField.toDate();
    } else if (dateField is DateTime) {
      parsedDate = dateField;
    }

    double parseDouble(dynamic v) {
      if (v == null) return 0.0;
      if (v is double) return v;
      if (v is int) return v.toDouble();
      if (v is String) return double.tryParse(v) ?? 0.0;
      if (v is num) return v.toDouble();
      return 0.0;
    }

    return AlertModel(
      id: doc.id,
      titre: data['titre'] ?? '',
      message: data['message'] ?? '',
      latitude: parseDouble(data['latitude']),
      longitude: parseDouble(data['longitude']),
      date: parsedDate,
      reporterId: data['reporterId'] as String?,
      imageUrl: data['imageUrl'] as String?,
      accuracy: data['accuracy'] != null ? parseDouble(data['accuracy']) : null,
    );
  }

  Map<String, dynamic> toMap() => {
        'titre': titre,
        'message': message,
        'latitude': latitude,
        'longitude': longitude,
        'date': date,
        if (reporterId != null) 'reporterId': reporterId,
        if (imageUrl != null) 'imageUrl': imageUrl,
        if (accuracy != null) 'accuracy': accuracy,
      };
}
