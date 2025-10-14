import 'package:flutter/material.dart';
import '../services/alert_service.dart';
import '../models/alert_model.dart';
import 'alerte_detail.dart';

class UserAlertsPage extends StatelessWidget {
  final String uid;
  final AlertService _alertService = AlertService();

  UserAlertsPage({super.key, required this.uid});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alertes de l\'utilisateur'),
        backgroundColor: Colors.redAccent,
      ),
      body: StreamBuilder<List<AlertModel>>(
        stream: _alertService.streamAlertesByUser(uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final alertes = snapshot.data ?? [];
          if (alertes.isEmpty) {
            return const Center(child: Text('Aucune alerte trouvée'));
          }

          return ListView.builder(
            itemCount: alertes.length,
            itemBuilder: (context, index) {
              final alerte = alertes[index];
              return ListTile(
                title: Text(alerte.titre),
                subtitle: Text(alerte.message),
                trailing: Text(
                  alerte.date != null ? alerte.date!.toLocal().toString() : '',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
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
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
