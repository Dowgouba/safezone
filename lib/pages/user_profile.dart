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

  TextEditingController _nameController = TextEditingController();
  TextEditingController _surnameController = TextEditingController();
  TextEditingController _phoneController = TextEditingController();
  TextEditingController _emailController = TextEditingController();

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
      setState(() {});
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

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    return Scaffold(
      appBar: AppBar(title: const Text('Profil utilisateur')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickImageAndUpload,
              child: CircleAvatar(
                radius: 50,
                backgroundImage: _photoUrl != null
                    ? NetworkImage(_photoUrl!)
                    : (_auth.currentUser!.photoURL != null ? NetworkImage(_auth.currentUser!.photoURL!) : null) as ImageProvider<Object>?,
                child: (_photoUrl == null && _auth.currentUser!.photoURL == null)
                    ? const Icon(Icons.person, size: 50)
                    : null,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Nom'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _surnameController,
              decoration: const InputDecoration(labelText: 'Prénom'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(labelText: 'Téléphone'),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            const Text('Contacts prédéfinis', style: TextStyle(fontWeight: FontWeight.bold)),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _contacts.length,
              itemBuilder: (context, index) {
                final contact = _contacts[index];
                return ListTile(
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
                );
              },
            ),
            ElevatedButton(
              onPressed: () => _addOrEditContact(),
              child: const Text('Ajouter un contact'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _saveProfile,
              child: const Text('Sauvegarder le profil'),
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
