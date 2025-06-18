import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService extends GetxService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Rx<User?> get user => Rx<User?>(_auth.currentUser);
  Stream<User?> get userStream => _auth.authStateChanges();

  Future<User?> signInAnonymously() async {
    try {
      final credential = await _auth.signInAnonymously();
      return credential.user;
    } catch (e) {
      print('Erreur lors de la connexion anonyme: $e');
      return null;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  String? get currentUserId => _auth.currentUser?.uid;

  @override
  void onInit() {
    super.onInit();
    user.bindStream(userStream);
  }
}
