import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';
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

  bool isEditing = false;
  String? photoUrl;

  String get currentUid => auth.currentUser!.uid;
  String get viewedUid => widget.uid ?? currentUid;

  Future<void> _pickImageAndUpload() async {
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      imageQuality: 85,
    );
    if (picked == null) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Téléchargement en cours...')));

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
        throw Exception('Échec du téléchargement (${resp.statusCode})');
      }

      final downloadUrl =
          'https://firebasestorage.googleapis.com/v0/b/$bucket/o/${Uri.encodeComponent(path)}?alt=media';

      await firestore.collection('users').doc(viewedUid).update({
        'photoUrl': downloadUrl,
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Photo mise à jour !')));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Erreur: $e')));
    }
  }

  Future<void> _saveProfile() async {
    try {
      final user = auth.currentUser!;
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
          return;
        }
      }

      await firestore.collection('users').doc(viewedUid).update({
        'name': nameController.text.trim(),
        'surname': surnameController.text.trim(),
        'phone': phoneController.text.trim(),
        'email': emailController.text.trim(),
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Profil mis à jour !')));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Erreur: $e')));
    }
  }

  Future<void> _logout() async {
    try {
      await auth.signOut();
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Erreur: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: firestore.collection('users').doc(viewedUid).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Center(child: Text('Utilisateur introuvable'));
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;
        nameController.text = data['name'] ?? '';
        surnameController.text = data['surname'] ?? '';
        phoneController.text = data['phone'] ?? '';
        emailController.text = data['email'] ?? '';
        photoUrl = data['photoUrl'];

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Card(
            elevation: 6,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: isEditing ? _pickImageAndUpload : null,
                    child: CircleAvatar(
                      radius: 55,
                      backgroundImage: photoUrl != null
                          ? CachedNetworkImageProvider(photoUrl!)
                          : null,
                      backgroundColor: Colors.grey[200],
                      child: (photoUrl == null)
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
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        icon: Icon(isEditing ? Icons.save : Icons.edit),
                        label: Text(isEditing ? 'Enregistrer' : 'Modifier'),
                        onPressed: () {
                          if (isEditing) _saveProfile();
                          setState(() => isEditing = !isEditing);
                        },
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.logout),
                        label: const Text('Déconnexion'),
                        onPressed: _logout,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
