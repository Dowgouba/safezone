import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/alert_service.dart';
import '../services/user_service.dart';
import 'theme.dart';

class AjoutAlertePage extends StatefulWidget {
  const AjoutAlertePage({super.key});

  @override
  State<AjoutAlertePage> createState() => _AjoutAlertePageState();
}

class _AjoutAlertePageState extends State<AjoutAlertePage> {
  final _formKey = GlobalKey<FormState>();
  final _titreController = TextEditingController();
  final _messageController = TextEditingController();
  final _searchController = TextEditingController();
  bool _loading = false;

  final AlertService _alertService = AlertService();
  final UserService _userService = UserService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<Map<String, dynamic>> _contacts = [];
  List<Map<String, dynamic>> _filteredContacts = [];
  Map<String, bool> _selectedContacts = {};
  bool _selectAll = false;

  @override
  void initState() {
    super.initState();
    _loadContacts();
    _searchController.addListener(_filterContacts);
  }

  Future<void> _loadContacts() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final userData = await _userService.getUserData(uid);
    final contacts = List<Map<String, dynamic>>.from(userData?['contacts'] ?? []);
    setState(() {
      _contacts = contacts;
      _filteredContacts = List.from(_contacts);
      _selectedContacts = {for (var c in contacts) c['phone']: false};
    });
  }

  void _filterContacts() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredContacts = _contacts
          .where((c) =>
              c['name'].toString().toLowerCase().contains(query) ||
              c['phone'].toString().contains(query))
          .toList();
    });
  }

  void _toggleSelectAll() {
    setState(() {
      _selectAll = !_selectAll;
      for (var c in _contacts) {
        _selectedContacts[c['phone']] = _selectAll;
      }
    });
  }

  Future<Position> _getPosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) throw Exception('Service de localisation désactivé');

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Permission refusée');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      throw Exception('Permission refusée définitivement');
    }

    return await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
  }

  Future<void> _ajouterAlerte() async {
    if (!_formKey.currentState!.validate()) return;

    final selected = _contacts
        .where((c) => _selectedContacts[c['phone']] == true)
        .toList();

    if (selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner au moins un contact')),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final position = await _getPosition();
      final user = _auth.currentUser;

      for (var c in selected) {
        await _alertService.addAlerte(
          titre: _titreController.text.trim(),
          message: _messageController.text.trim(),
          latitude: position.latitude,
          longitude: position.longitude,
          reporterId: user?.uid,
          contactName: c['name'],
          contactPhone: c['phone'],
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Alerte envoyée à tous les contacts sélectionnés !')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur : $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _titreController.dispose();
    _messageController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Signaler une alerte"),
        backgroundColor: appTheme.primaryColor,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                elevation: 6,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: _titreController,
                          decoration: InputDecoration(
                            labelText: 'Titre de l’alerte',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          validator: (val) => val == null || val.isEmpty ? 'Entrez un titre' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _messageController,
                          decoration: InputDecoration(
                            labelText: 'Message',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          validator: (val) => val == null || val.isEmpty ? 'Entrez un message' : null,
                          maxLines: 4,
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                decoration: InputDecoration(
                                  labelText: 'Rechercher un contact',
                                  prefixIcon: const Icon(Icons.search),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton(
                              onPressed: _toggleSelectAll,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: appTheme.primaryColor,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: Text(_selectAll ? 'Tout désélectionner' : 'Tout sélectionner'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.grey.shade50,
                          ),
                          height: 200,
                          child: Scrollbar(
                            child: ListView.builder(
                              itemCount: _filteredContacts.length,
                              itemBuilder: (context, index) {
                                final c = _filteredContacts[index];
                                return CheckboxListTile(
                                  title: Text('${c['name']} (${c['phone']})'),
                                  value: _selectedContacts[c['phone']] ?? false,
                                  onChanged: (val) {
                                    setState(() => _selectedContacts[c['phone']] = val!);
                                  },
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        _loading
                            ? const Center(child: CircularProgressIndicator())
                            : ElevatedButton.icon(
                                icon: const Icon(Icons.warning),
                                label: const Text("Envoyer l’alerte"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: appTheme.primaryColor,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: _ajouterAlerte,
                              ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
