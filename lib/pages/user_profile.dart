import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

import '../firebase_options.dart';

class UserProfilePage extends StatefulWidget {
  final String? uid; // optional: if null, show current user's profile

  const UserProfilePage({super.key, this.uid});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final _picker = ImagePicker();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _surnameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  List<Map<String, dynamic>> _contacts = [];
  String? _photoUrl;

  bool _loading = true;

  String get currentUid => _auth.currentUser!.uid;
  String get viewedUid => widget.uid ?? currentUid;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final doc = await _firestore.collection('users').doc(viewedUid).get();
    if (!doc.exists) return;

    final data = doc.data()!;
    _nameController.text = data['name'] ?? '';
    _surnameController.text = data['surname'] ?? '';
    _phoneController.text = data['phone'] ?? '';
    _emailController.text = data['email'] ?? '';
    _contacts = List<Map<String, dynamic>>.from(data['contacts'] ?? []);
    _photoUrl = data['photoUrl'] as String?;
    setState(() => _loading = false);
  }

  Future<void> _pickImageAndUpload() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery, maxWidth: 1200, imageQuality: 85);
    if (picked == null) return;

    setState(() => _loading = true);

    try {
      final fileBytes = await picked.readAsBytes();
      final bucket = DefaultFirebaseOptions.currentPlatform.storageBucket;
      final path = 'user_photos/$viewedUid/${DateTime.now().millisecondsSinceEpoch}.jpg';

      final currentUser = _auth.currentUser;
      if (currentUser == null) throw Exception('Utilisateur non connecté');
      final token = await currentUser.getIdToken();

      final uri = Uri.parse('https://firebasestorage.googleapis.com/v0/b/$bucket/o?name=${Uri.encodeComponent(path)}&uploadType=media');
      final resp = await http.post(uri, headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'image/jpeg'
      }, body: fileBytes);

      if (resp.statusCode != 200 && resp.statusCode != 201) {
        throw Exception('Upload failed: ${resp.statusCode} ${resp.body}');
      }

      final downloadUrl = 'https://firebasestorage.googleapis.com/v0/b/$bucket/o/${Uri.encodeComponent(path)}?alt=media';

      await _firestore.collection('users').doc(viewedUid).update({'photoUrl': downloadUrl});
      setState(() {
        _photoUrl = downloadUrl;
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Photo uploadée')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
    }

    setState(() => _loading = false);
  }

  Future<void> _saveProfile() async {
    try {
      await _firestore.collection('users').doc(viewedUid).update({
        'name': _nameController.text.trim(),
        'surname': _surnameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'email': _emailController.text.trim(),
        'contacts': _contacts,
      });

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profil mis à jour avec succès')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
    }
  }

  void _addOrEditContact({Map<String, dynamic>? contact, int? index}) {
    final _contactNameController =
        TextEditingController(text: contact != null ? contact['name'] : '');
    final _contactPhoneController =
        TextEditingController(text: contact != null ? contact['phone'] : '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(contact != null ? 'Modifier contact' : 'Ajouter contact'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _contactNameController,
              decoration: const InputDecoration(labelText: 'Nom du contact'),
            ),
            TextField(
              controller: _contactPhoneController,
              decoration: const InputDecoration(labelText: 'Téléphone'),
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              final newContact = {
                'name': _contactNameController.text.trim(),
                'phone': _contactPhoneController.text.trim(),
              };
              setState(() {
                if (index != null) {
                  _contacts[index] = newContact;
                } else {
                  _contacts.add(newContact);
                }
              });
              Navigator.pop(context);
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteContact(int index) async {
    setState(() => _contacts.removeAt(index));
  }

  Future<void> _logout() async {
    await _auth.signOut();
    if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil utilisateur'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Déconnexion',
            onPressed: _logout,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              elevation: 6,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _pickImageAndUpload,
                      child: CircleAvatar(
                        radius: 50,
                        backgroundImage: _photoUrl != null
                            ? NetworkImage(_photoUrl!)
                            : (_auth.currentUser!.photoURL != null
                                ? NetworkImage(_auth.currentUser!.photoURL!)
                                : null) as ImageProvider<Object>?,
                        backgroundColor: Colors.grey[200],
                        child: (_photoUrl == null && _auth.currentUser!.photoURL == null)
                            ? const Icon(Icons.person, size: 50, color: Colors.grey)
                            : null,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${_nameController.text} ${_surnameController.text}',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _emailController.text,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.blueGrey),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nom',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _surnameController,
              decoration: const InputDecoration(
                labelText: 'Prénom',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Téléphone',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Contacts prédéfinis', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ElevatedButton.icon(
                  onPressed: () => _addOrEditContact(),
                  icon: const Icon(Icons.add),
                  label: const Text('Ajouter'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _contacts.length,
              itemBuilder: (context, index) {
                final contact = _contacts[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    leading: const Icon(Icons.contact_phone),
                    title: Text(contact['name'] ?? ''),
                    subtitle: Text(contact['phone'] ?? ''),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _addOrEditContact(contact: contact, index: index),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => _deleteContact(index),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _saveProfile,
                icon: const Icon(Icons.save),
                label: const Text('Sauvegarder le profil'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _surnameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }
}