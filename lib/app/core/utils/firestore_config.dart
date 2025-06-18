import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreConfig {
  static Future<void> initialize() async {
    final firestore = FirebaseFirestore.instance;

    // Activer la persistance hors ligne
    await firestore.enablePersistence(
      const PersistenceSettings(synchronizeTabs: true),
    );

    // Configurer les paramètres de cache
    firestore.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: 50 * 1024 * 1024, // 50 MB
    );

    print('Firestore configuré avec persistance hors ligne');
  }
}
