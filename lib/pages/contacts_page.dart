import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/user_service.dart';

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
    if (name.isEmpty || phone.isEmpty) return;

    setState(() => _loading = true);
    try {
      final data = await _userService.getUserData(uid);
      final contacts = List<Map<String, dynamic>>.from(data?['contacts'] ?? []);
      contacts.add({'name': name, 'phone': phone});
      await _userService.updateUser(uid, {'contacts': contacts});
      _nameController.clear();
      _phoneController.clear();
      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
    }
    setState(() => _loading = false);
  }

  Future<void> _removeContact(String uid, int index) async {
    setState(() => _loading = true);
    try {
      final data = await _userService.getUserData(uid);
      final contacts = List<Map<String, dynamic>>.from(data?['contacts'] ?? []);
      if (index < 0 || index >= contacts.length) return;
      contacts.removeAt(index);
      await _userService.updateUser(uid, {'contacts': contacts});
      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final current = FirebaseAuth.instance.currentUser;
    if (current == null) {
      return Scaffold(body: Center(child: Text('Veuillez vous connecter pour gérer vos contacts')));
    }

    final uid = current.uid;

    return Scaffold(
      appBar: AppBar(title: const Text('Contacts prédéfinis'), backgroundColor: Colors.redAccent),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _userService.getUserData(uid),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          final data = snap.data ?? {};
          final contacts = List<Map<String, dynamic>>.from(data['contacts'] ?? []);

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: contacts.length,
                    itemBuilder: (context, i) {
                      final c = contacts[i];
                      return ListTile(
                        title: Text(c['name'] ?? ''),
                        subtitle: Text(c['phone'] ?? ''),
                        trailing: IconButton(icon: const Icon(Icons.delete), onPressed: () => _removeContact(uid, i)),
                      );
                    },
                  ),
                ),
                const Divider(),
                TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Nom')),
                TextField(controller: _phoneController, decoration: const InputDecoration(labelText: 'Téléphone')),
                const SizedBox(height: 8),
                _loading ? const CircularProgressIndicator() : ElevatedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Ajouter un contact'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                  onPressed: () => _addContact(uid),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
