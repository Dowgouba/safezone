import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

import '../firebase_options.dart';

class UserProfilePage extends StatefulWidget {
  final String? uid;

  const UserProfilePage({super.key, this.uid});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseAuth auth = FirebaseAuth.instance;
  final ImagePicker picker = ImagePicker();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController surnameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();

  String? photoUrl;
  bool loading = true;
  bool isEditing = false;

  String get currentUid => auth.currentUser!.uid;
  String get viewedUid => widget.uid ?? currentUid;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final doc = await firestore.collection('users').doc(viewedUid).get();
    if (!doc.exists) return;

    final data = doc.data()!;
    nameController.text = data['name'] ?? '';
    surnameController.text = data['surname'] ?? '';
    phoneController.text = data['phone'] ?? '';
    emailController.text = data['email'] ?? '';
    photoUrl = data['photoUrl'] as String?;
    setState(() => loading = false);
  }

  Future<void> _pickImageAndUpload() async {
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      imageQuality: 85,
    );
    if (picked == null) return;

    setState(() => loading = true);

    try {
      final fileBytes = await picked.readAsBytes();
      final bucket = DefaultFirebaseOptions.currentPlatform.storageBucket;
      final path =
          'user_photos/$viewedUid/${DateTime.now().millisecondsSinceEpoch}.jpg';

      final currentUser = auth.currentUser;
      if (currentUser == null) throw Exception('Utilisateur non connecté');
      final token = await currentUser.getIdToken();

      final uri = Uri.parse(
          'https://firebasestorage.googleapis.com/v0/b/$bucket/o?name=${Uri.encodeComponent(path)}&uploadType=media');
      final resp = await http.post(uri, headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'image/jpeg'
      }, body: fileBytes);

      if (resp.statusCode != 200 && resp.statusCode != 201) {
        throw Exception('Upload failed: ${resp.statusCode} ${resp.body}');
      }

      final downloadUrl =
          'https://firebasestorage.googleapis.com/v0/b/$bucket/o/${Uri.encodeComponent(path)}?alt=media';

      await firestore
          .collection('users')
          .doc(viewedUid)
          .update({'photoUrl': downloadUrl});
      setState(() {
        photoUrl = downloadUrl;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Photo uploadée')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Erreur: $e')));
    }

    setState(() => loading = false);
  }

  Future<void> _saveProfile() async {
    try {
      final user = auth.currentUser!;
      // Si l'email a changé, ré-authentifier et mettre à jour
      if (emailController.text.trim() != user.email) {
        final passwordController = TextEditingController();
        final result = await showDialog<String>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Confirmer email"),
            content: TextField(
              controller: passwordController,
              obscureText: true,
              decoration:
                  const InputDecoration(labelText: "Mot de passe actuel"),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Annuler")),
              ElevatedButton(
                  onPressed: () =>
                      Navigator.pop(context, passwordController.text.trim()),
                  child: const Text("Valider"))
            ],
          ),
        );
        if (result != null && result.isNotEmpty) {
          final credential = EmailAuthProvider.credential(
              email: user.email!, password: result);
          await user.reauthenticateWithCredential(credential);
          await user.updateEmail(emailController.text.trim());
        } else {
          // Annulé par l'utilisateur
          return;
        }
      }

      await firestore.collection('users').doc(viewedUid).update({
        'name': nameController.text.trim(),
        'surname': surnameController.text.trim(),
        'phone': phoneController.text.trim(),
        'email': emailController.text.trim(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Profil mis à jour')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Erreur: $e')));
    }
  }

  Future<void> _changePassword() async {
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Changer le mot de passe"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: oldPasswordController,
              obscureText: true,
              decoration:
                  const InputDecoration(labelText: "Ancien mot de passe"),
            ),
            TextField(
              controller: newPasswordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: "Nouveau mot de passe"),
            ),
            TextField(
              controller: confirmController,
              obscureText: true,
              decoration: const InputDecoration(labelText: "Confirmer"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Annuler"),
          ),
          ElevatedButton(
            onPressed: () async {
              final newPass = newPasswordController.text.trim();
              final confirmPass = confirmController.text.trim();

              if (newPass != confirmPass) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text("Les mots de passe ne correspondent pas")));
                return;
              }

              try {
                final user = auth.currentUser!;
                await user.updatePassword(newPass);
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text("Mot de passe changé avec succès")));
                Navigator.pop(context);
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Erreur: $e")));
              }
            },
            child: const Text("Changer"),
          ),
        ],
      ),
    );
  }

  Future<void> _logout() async {
    try {
      await auth.signOut();
      if (!mounted) return;

      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur lors de la déconnexion: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Modifier Profil' : 'Profil utilisateur'),
        actions: [
          IconButton(
            icon: Icon(isEditing ? Icons.save : Icons.edit),
            onPressed: () {
              if (isEditing) _saveProfile();
              setState(() => isEditing = !isEditing);
            },
          ),
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
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: isEditing ? _pickImageAndUpload : null,
                      child: CircleAvatar(
                        radius: 50,
                        backgroundImage: photoUrl != null
                            ? NetworkImage(photoUrl!)
                            : (auth.currentUser!.photoURL != null
                                ? NetworkImage(auth.currentUser!.photoURL!)
                                : null) as ImageProvider<Object>?,
                        backgroundColor: Colors.grey[200],
                        child: (photoUrl == null &&
                                auth.currentUser!.photoURL == null)
                            ? const Icon(Icons.person, size: 50)
                            : null,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nameController,
                      readOnly: !isEditing,
                      decoration: const InputDecoration(
                        labelText: 'Nom',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: surnameController,
                      readOnly: !isEditing,
                      decoration: const InputDecoration(
                        labelText: 'Prénom',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: emailController,
                      readOnly: !isEditing,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: phoneController,
                      readOnly: !isEditing,
                      decoration: const InputDecoration(
                        labelText: 'Téléphone',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: isEditing ? _changePassword : null,
                      child: const Text("Changer le mot de passe"),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
