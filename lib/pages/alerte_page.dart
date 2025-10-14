import 'package:flutter/material.dart';
import '../services/alert_service.dart';
import '../services/user_service.dart';
import '../models/alert_model.dart';
import 'alerte_detail.dart';
import 'user_profile.dart';
import 'alerteform.dart';

class AlertePage extends StatelessWidget {
  const AlertePage({super.key});

  @override
  Widget build(BuildContext context) {
    final alertService = AlertService();
    final userService = UserService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Liste des alertes'),
        backgroundColor: const Color.fromARGB(255, 108, 97, 97),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_alert),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AjoutAlertePage()),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<List<AlertModel>>(
        stream: alertService.streamAlertes(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final alertes = snapshot.data ?? [];
          if (alertes.isEmpty) {
            return const Center(child: Text('Aucune alerte disponible.'));
          }

          return ListView.builder(
            itemCount: alertes.length,
            itemBuilder: (context, index) {
              final alerte = alertes[index];

              return Card(
                color: Colors.red.shade50,
                margin:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: ListTile(
                  title: Text(
                    alerte.titre,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(alerte.message),
                      const SizedBox(height: 6),
                      if (alerte.reporterId != null)
                        FutureBuilder<Map<String, dynamic>?>(
                          future: userService.getUserData(alerte.reporterId!),
                          builder: (context, userSnap) {
                            if (userSnap.connectionState ==
                                ConnectionState.waiting) {
                              return const SizedBox.shrink();
                            }
                            final data = userSnap.data;
                            if (data == null) {
                              return const Text('Utilisateur inconnu',
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
                                        uid: alerte.reporterId!),
                                  ),
                                );
                              },
                              child: Text('Signalé par : $username',
                                  style: const TextStyle(color: Colors.blue)),
                            );
                          },
                        ),
                      const SizedBox(height: 4),
                      Text(
                        "📍 Position: (${alerte.latitude.toStringAsFixed(4)}, ${alerte.longitude.toStringAsFixed(4)})",
                        style: const TextStyle(color: Colors.grey),
                      ),
                      Text(
                        alerte.date != null
                            ? "🕒 ${alerte.date!.toLocal()}"
                            : '🕒 Date inconnue',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
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
                        await alertService.deleteAlerte(alerte.id);
                      }
                    },
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
                          id: alerte.id,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
