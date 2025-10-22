import 'package:flutter/material.dart';
import 'package:safezone/pages/contacts_page.dart';
import 'alerte_page.dart';
import 'alerteform.dart';
import 'map_page.dart';
import 'user_profile.dart';

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
    const ContactsPage(),
    const UserProfilePage(),
  ];

  final List<String> _pageTitles = ["Carte", "Listes des Alertes", "Mes Contacts prédéfinis", "Utilisateur connecté"];

  void _onFabPressed() {
    // Le FAB fonctionne partout, mais redirige toujours vers l'ajout d'alerte
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AjoutAlertePage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 4, 68, 120),
        elevation: 0,
        title: Row(
          children: [
            Image.asset('assets/logo.jpg', height: 32, width: 32),
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
        heroTag: 'global_fab',
        onPressed: _onFabPressed,
        backgroundColor: Colors.redAccent, // 🔴 couleur uniforme
        child: const Icon(Icons.add_alert, color: Colors.white),
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
