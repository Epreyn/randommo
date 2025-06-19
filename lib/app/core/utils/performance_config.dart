// lib/app/core/utils/performance_config.dart
class PerformanceConfig {
  // Configuration du cache
  static const int maxCacheSize = 1000; // Nombre max de tuiles en cache
  static const Duration cacheExpiration = Duration(minutes: 10);

  // Configuration des requêtes
  static const int batchSize = 10; // Taille max des requêtes batch Firestore
  static const Duration minUpdateInterval = Duration(milliseconds: 100);
  static const Duration requestTimeout = Duration(seconds: 5);

  // Configuration du préchargement
  static const int preloadRadius = 3; // Rayon de préchargement autour du joueur
  static const int initialPreloadRadius = 10; // Rayon de préchargement initial

  // Configuration de l'affichage
  static const int defaultViewRadius = 5;
  static const int maxViewRadius = 10;

  // Configuration des animations
  static const Duration movementAnimationDuration = Duration(milliseconds: 200);
  static const Duration snackbarDuration = Duration(milliseconds: 800);
  static const Duration tileRevealDuration = Duration(milliseconds: 600);
  static const int tileRevealDelayFactor = 50; // ms par unité de distance

  // Optimisations Firestore
  static const bool enableOfflinePersistence = true;
  static const int cacheSizeBytes = 50 * 1024 * 1024; // 50 MB
}
