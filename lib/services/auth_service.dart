import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;

  // Inscription
  Future<User?> register({
    required String email,
    required String password,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
        email: email, password: password);
    return cred.user;
  }

  // Connexion
  Future<User?> login({
    required String email,
    required String password,
  }) async {
    final cred = await _auth.signInWithEmailAndPassword(
        email: email, password: password);
    return cred.user;
  }

  // Déconnexion
  Future<void> logout() async {
    await _auth.signOut();
  }

  // Écoute de l'état de l'utilisateur
  Stream<User?> authStateChanges() => _auth.authStateChanges();
}
