import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  // Plugin de notifications locales
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  /// Initialise les notifications locales (Android + iOS)
  Future<void> init() async {
    final androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    final iOSSettings = DarwinInitializationSettings();
    final settings = InitializationSettings(
      android: androidSettings,
      iOS: iOSSettings,
    );

    // Initialisation du plugin
    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (details) {
        // Callback quand l'utilisateur appuie sur la notification
        // Tu peux gérer ici la navigation vers une page spécifique
      },
    );
  }

  /// Affiche une notification locale
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      'safezone_channel', // ID du canal
      'SafeZone Alerts', // Nom du canal
      channelDescription: 'Notifications pour SafeZone',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
    );

    final iOSDetails = DarwinNotificationDetails();

    final notificationDetails =
        NotificationDetails(android: androidDetails, iOS: iOSDetails);

    await _plugin.show(id, title, body, notificationDetails);
  }
}
