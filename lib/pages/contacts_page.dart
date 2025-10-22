import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/user_service.dart';
import 'theme.dart'; // <- Import de ton theme global

class ContactsPage extends StatefulWidget {
  const ContactsPage({super.key});

  @override
  State<ContactsPage> createState() => _ContactsPageState();
}

class _ContactsPageState extends State<ContactsPage> {
  final _userService = UserService();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _loading = false;

  Future<void> _addContact(String uid) async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();

    if (name.isEmpty || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez remplir tous les champs.')),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final data = await _userService.getUserData(uid);
      final contacts = List<Map<String, dynamic>>.from(data?['contacts'] ?? []);

      if (contacts.any((c) => c['phone'] == phone)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ce contact existe déjà.')),
        );
      } else {
        contacts.add({'name': name, 'phone': phone});
        await _userService.updateUser(uid, {'contacts': contacts});
        _nameController.clear();
        _phoneController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Contact ajouté avec succès !')),
        );
        setState(() {});
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur : $e')),
      );
    }
    setState(() => _loading = false);
  }

  Future<void> _removeContact(String uid, int index) async {
    setState(() => _loading = true);
    try {
      final data = await _userService.getUserData(uid);
      final contacts = List<Map<String, dynamic>>.from(data?['contacts'] ?? []);

      if (index < 0 || index >= contacts.length) return;
      final removed = contacts[index];

      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Supprimer le contact'),
          content: Text('Voulez-vous supprimer ${removed['name']} ?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: appTheme.primaryColor,
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Supprimer'),
            ),
          ],
        ),
      );

      if (ok == true) {
        contacts.removeAt(index);
        await _userService.updateUser(uid, {'contacts': contacts});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Contact supprimé.')),
        );
        setState(() {});
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur : $e')),
      );
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return const Scaffold(
        body: Center(
          child: Text('Veuillez vous connecter pour gérer vos contacts'),
        ),
      );
    }

    final uid = currentUser.uid;

    return Scaffold(
      body: SafeArea(
        child: FutureBuilder<Map<String, dynamic>?>(
          future: _userService.getUserData(uid),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final data = snapshot.data ?? {};
            final contacts = List<Map<String, dynamic>>.from(data['contacts'] ?? []);

            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Expanded(
                    child: contacts.isEmpty
                        ? Center(
                            child: Text(
                              'Aucun contact pour le moment.\nAjoutez vos numéros de confiance.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: appTheme.hintColor),
                            ),
                          )
                        : ListView.builder(
                            itemCount: contacts.length,
                            itemBuilder: (context, i) {
                              final c = contacts[i];
                              return Card(
                                elevation: 3,
                                margin: const EdgeInsets.symmetric(vertical: 6),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: appTheme.primaryColor,
                                    child: const Icon(Icons.person, color: Colors.white),
                                  ),
                                  title: Text(
                                    c['name'] ?? '',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  subtitle: Text(c['phone'] ?? '', style: TextStyle(color: appTheme.hintColor)),
                                  trailing: IconButton(
                                    icon: Icon(Icons.delete, color: appTheme.primaryColor),
                                    onPressed: () => _removeContact(uid, i),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: appTheme.cardColor,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: appTheme.dividerColor),
                    ),
                    child: Column(
                      children: [
                        TextField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            labelText: 'Nom du contact',
                            prefixIcon: const Icon(Icons.person_outline),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            labelText: 'Numéro de téléphone',
                            prefixIcon: const Icon(Icons.phone),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _loading
                            ? const CircularProgressIndicator()
                            : SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  icon: const Icon(Icons.add),
                                  label: const Text('Ajouter un contact'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: appTheme.primaryColor,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  onPressed: () => _addContact(uid),
                                ),
                              ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
