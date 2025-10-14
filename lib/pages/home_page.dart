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
    // placeholder pour profil utilisateur
    Container(
      color: Colors.white,
      child: const Center(
          child: Text('Profil', style: TextStyle(fontSize: 20))),
    ),
  ];

  final List<String> _pageTitles = ["Carte", "Alertes", "Profil"];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_pageTitles[_currentIndex])),
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
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.map), label: "Carte"),
          BottomNavigationBarItem(icon: Icon(Icons.warning), label: "Alertes"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profil"),
        ],
      ),
    );
  }
}
