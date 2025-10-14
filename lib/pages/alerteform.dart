import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/alert_service.dart';
import '../services/user_service.dart';

class AjoutAlertePage extends StatefulWidget {
  const AjoutAlertePage({super.key});

  @override
  State<AjoutAlertePage> createState() => _AjoutAlertePageState();
}

class _AjoutAlertePageState extends State<AjoutAlertePage> {
  final _formKey = GlobalKey<FormState>();
  final _titreController = TextEditingController();
  final _messageController = TextEditingController();
  bool _loading = false;

  final AlertService _alertService = AlertService();
  final UserService _userService = UserService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<Map<String, dynamic>> _contacts = [];
  Map<String, dynamic>? _selectedContact;

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    final uid = _auth.currentUser!.uid;
    final userData = await _userService.getUserData(uid);
    setState(() {
      _contacts = List<Map<String, dynamic>>.from(userData?['contacts'] ?? []);
    });
  }

  Future<Position> _getPosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) throw Exception('Service de localisation désactivé');

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) throw Exception('Permission refusée');
    }
    if (permission == LocationPermission.deniedForever) throw Exception('Permission refusée définitivement');

    return await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
  }

  Future<void> _ajouterAlerte() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      final position = await _getPosition();
      final user = _auth.currentUser;

      // On peut stocker ici le contact choisi
      final contactPhone = _selectedContact?['phone'];
      final contactName = _selectedContact?['name'];

      await _alertService.addAlerte(
        titre: _titreController.text.trim(),
        message: _messageController.text.trim(),
        latitude: position.latitude,
        longitude: position.longitude,
        reporterId: user?.uid,
        // On stocke le contact à notifier
        imageUrl: null,
        accuracy: position.accuracy,
        contactName: contactName,
        contactPhone: contactPhone,
      );

      // Optionnel: envoyer notification au contact via service externe ou SMS si implémenté
      if (contactPhone != null) {
        print('Alerte envoyée au contact : $contactPhone');
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Alerte ajoutée avec succès !')));
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur : $e')));
    }
    setState(() => _loading = false);
  }

  @override
  void dispose() {
    _titreController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Signaler une alerte")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _titreController,
                decoration: const InputDecoration(labelText: 'Titre de l’alerte'),
                validator: (val) => val == null || val.isEmpty ? 'Entrez un titre' : null,
              ),
              TextFormField(
                controller: _messageController,
                decoration: const InputDecoration(labelText: 'Message'),
                validator: (val) => val == null || val.isEmpty ? 'Entrez un message' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<Map<String, dynamic>>(
                decoration: const InputDecoration(
                  labelText: 'Notifier un contact prédéfini',
                ),
                value: _selectedContact,
                items: _contacts
                    .map(
                      (c) => DropdownMenuItem(
                        value: c,
                        child: Text('${c['name']} (${c['phone']})'),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  setState(() => _selectedContact = value);
                },
              ),
              const SizedBox(height: 24),
              _loading
                  ? const CircularProgressIndicator()
                  : ElevatedButton.icon(
                      icon: const Icon(Icons.warning),
                      label: const Text("Envoyer l’alerte"),
                      onPressed: _ajouterAlerte,
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
