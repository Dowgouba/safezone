import 'package:flutter/material.dart';
import 'alerte_page.dart';
import 'alerteform.dart';
import 'map_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  final List<Widget> _pagesWidgets = [
    const MapPage(),
    const AlertePage(),
    // Onglet Contacts
    Container(
      color: Colors.white,
      child: const Center(
        child: Text('Contacts', style: TextStyle(fontSize: 20)),
      ),
    ),
    // Onglet Profil
    Container(
      color: Colors.white,
      child: const Center(
        child: Text('Profil', style: TextStyle(fontSize: 20)),
      ),
    ),
  ];

  final List<String> _pageTitles = ["Carte", "Alertes", "Contacts", "Profil"];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue, // Couleur bleue pour la top barre
        elevation: 0,
        centerTitle: false, // Pour aligner à gauche
        title: Row(
          children: [
            Image.asset(
              'assets/logo.jpg', // Remplace par le chemin de ton logo si besoin
              height: 32,
              width: 32,
            ),
            const SizedBox(width: 10),
            const Text(
              'SafeZone',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 22,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(width: 16),
            Text(
              _pageTitles[_currentIndex],
              style: const TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w400,
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),
      body: _pagesWidgets[_currentIndex],
      floatingActionButton: FloatingActionButton(
        heroTag: 'home_fab',
        onPressed: () {
          // Si on est sur la page Alertes, ouvrir le formulaire complet
          if (_currentIndex == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AjoutAlertePage()),
            );
          } else {
            // Pour Carte ou Profil, on peut définir d'autres actions si besoin
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Action non disponible ici.")));
          }
        },
        child: const Icon(Icons.add_alert),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: const Color(0xFF043A68),
        unselectedItemColor: const Color(0xFF043A68),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.map), label: "Carte"),
          BottomNavigationBarItem(icon: Icon(Icons.warning), label: "Alertes"),
          BottomNavigationBarItem(icon: Icon(Icons.contacts), label: "Contacts"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profil"),
        ],
      ),
    );
  }
}