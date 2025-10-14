import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/alert_model.dart';

class AlertService {
  final CollectionReference _alertsRef =
      FirebaseFirestore.instance.collection('alertes');

  // Stream de toutes les alertes, ordre décroissant par date
  Stream<List<AlertModel>> streamAlertes() {
    return _alertsRef
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AlertModel.fromFirestore(doc))
            .toList());
  }

  // Stream des alertes d'un utilisateur spécifique
  Stream<List<AlertModel>> streamAlertesByUser(String uid) {
    return _alertsRef
        .where('reporterId', isEqualTo: uid)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AlertModel.fromFirestore(doc))
            .toList());
  }

  // Ajouter une nouvelle alerte
  Future<void> addAlerte({
    required String titre,
    required String message,
    required double latitude,
    required double longitude,
    String? reporterId,
    String? imageUrl,
    double? accuracy,
    String? contactName,
    String? contactPhone,
  }) async {
    final data = {
      'titre': titre,
      'message': message,
      'date': FieldValue.serverTimestamp(),
      'latitude': latitude,
      'longitude': longitude,
    };

    if (reporterId != null) data['reporterId'] = reporterId;
    if (imageUrl != null) data['imageUrl'] = imageUrl;
    if (accuracy != null) data['accuracy'] = accuracy;
  if (contactName != null) data['contactName'] = contactName;
  if (contactPhone != null) data['contactPhone'] = contactPhone;

    await _alertsRef.add(data);
  }

  // Supprimer une alerte par son id
  Future<void> deleteAlerte(String id) async {
    await _alertsRef.doc(id).delete();
  }
}
