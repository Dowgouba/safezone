import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  final _pages = ["Carte", "Alertes", "Profil"];
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  File? _image;
  final _picker = ImagePicker();
  final _descriptionController = TextEditingController();

  Future<void> pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<void> sendAlert() async {
    if (_descriptionController.text.isEmpty && _image == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Alerte vide !")));
      return;
    }

    await _firestore.collection('alerts').add({
      'description': _descriptionController.text,
      'timestamp': FieldValue.serverTimestamp(),
      'imagePath': _image?.path ?? '',
    });

    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text("Alerte envoyée !")));

    setState(() {
      _descriptionController.clear();
      _image = null;
    });
  }

  void _showAlertDialog() {
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text("Nouvelle alerte"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                      hintText: "Décrire l'alerte ici"),
                ),
                const SizedBox(height: 10),
                _image != null
                    ? Image.file(_image!, height: 100)
                    : const SizedBox(),
                TextButton.icon(
                  onPressed: pickImage,
                  icon: const Icon(Icons.camera_alt),
                  label: const Text("Prendre une photo"),
                )
              ],
            ),
            actions: [
              TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text("Annuler")),
              ElevatedButton(
                  onPressed: () {
                    sendAlert();
                    Navigator.pop(context);
                  },
                  child: const Text("Envoyer")),
            ],
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_pages[_currentIndex])),
      body: Center(
        child: Text(
          _pages[_currentIndex],
          style: const TextStyle(fontSize: 30),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAlertDialog,
        child: const Icon(Icons.add_alert),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.map), label: "Carte"),
          BottomNavigationBarItem(
              icon: Icon(Icons.warning), label: "Alertes"),
          BottomNavigationBarItem(
              icon: Icon(Icons.person), label: "Profil"),
        ],
      ),
    );
  }
}
