// lib/app/modules/game/controllers/game_controller.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/models/position_model.dart';
import '../../../services/game_service.dart';
import '../../../services/world_generator_service.dart';
import 'player_controller.dart';
import 'world_controller.dart';

class GameController extends GetxController {
  final GameService _gameService = Get.find();
  final PlayerController playerController = Get.find();
  final WorldController worldController = Get.find();

  final RxBool isMoving = false.obs;
  final RxBool isInitialized = false.obs;

  // File d'attente pour les mouvements
  Position? _pendingMove;
  bool _isProcessingMove = false;

  @override
  void onInit() {
    super.onInit();
    _initializeGame();
  }

  Future<void> _initializeGame() async {
    print('Initialisation du jeu...');

    // Ne pas attendre trop longtemps
    await Future.delayed(const Duration(milliseconds: 100));

    final player = playerController.currentPlayer.value;

    // Si pas de joueur, attendre un peu mais pas trop
    if (player == null) {
      int attempts = 0;
      while (playerController.currentPlayer.value == null && attempts < 20) {
        await Future.delayed(const Duration(milliseconds: 100));
        attempts++;
      }
    }

    final finalPlayer = playerController.currentPlayer.value;
    if (finalPlayer == null) {
      print('Erreur: Joueur non disponible');
      // Marquer comme initialisé quand même pour éviter le blocage
      isInitialized.value = true;
      return;
    }

    try {
      print('Joueur trouvé: ${finalPlayer.id}');

      // Précharger la zone autour du spawn
      worldController.preloadArea(finalPlayer.position, 10);

      // Révéler les tuiles initiales seulement si c'est un nouveau joueur
      if (playerController.isFirstTime.value ||
          finalPlayer.revealedTiles.isEmpty) {
        await _gameService.revealTilesAround(
            finalPlayer.position, finalPlayer.id);
      }

      // Forcer le rafraîchissement
      worldController.refreshAllTiles();

      // Toujours marquer comme initialisé
      isInitialized.value = true;
      print('Initialisation terminée avec succès');
    } catch (e) {
      print('Erreur lors de l\'initialisation: $e');
      // Marquer comme initialisé même en cas d'erreur
      isInitialized.value = true;
    }
  }

  // Déplacement optimisé avec file d'attente
  Future<void> moveInDirection(int dx, int dy) async {
    // Si déjà en mouvement, mettre en file d'attente
    if (_isProcessingMove) {
      final player = playerController.currentPlayer.value;
      if (player != null) {
        _pendingMove = Position(
          x: player.position.x + dx,
          y: player.position.y + dy,
        );
      }
      return;
    }

    final player = playerController.currentPlayer.value;
    if (player == null || !isInitialized.value) return;

    final newPosition = Position(
      x: player.position.x + dx,
      y: player.position.y + dy,
    );

    if (!WorldGeneratorService.isValidMove(player.position, newPosition)) {
      return;
    }

    _isProcessingMove = true;
    isMoving.value = true;

    try {
      // Précharger la zone cible pendant le mouvement
      worldController.preloadArea(newPosition, 5);

      // Effectuer le mouvement
      final success = await playerController.moveToPosition(newPosition);

      if (!success) {
        // Feedback rapide d'échec
        Get.snackbar(
          'Mouvement impossible',
          'Cette case n\'est pas accessible',
          snackPosition: SnackPosition.TOP,
          duration: const Duration(milliseconds: 800),
          backgroundColor: Get.theme.colorScheme.error.withOpacity(0.8),
          colorText: Get.theme.colorScheme.onError,
          margin: const EdgeInsets.all(8),
          borderRadius: 8,
          isDismissible: true,
        );
      } else {
        // Attendre un peu pour laisser Firestore se synchroniser
        await Future.delayed(const Duration(milliseconds: 200));

        // Forcer le rafraîchissement des tuiles pour s'assurer que les nouvelles sont chargées
        worldController.refreshAllTiles();

        // Attendre encore un peu pour que le WorldController mette à jour ses listes
        await Future.delayed(const Duration(milliseconds: 100));
      }
    } catch (e) {
      print('Erreur lors du déplacement: $e');
      Get.snackbar(
        'Erreur',
        'Une erreur est survenue lors du déplacement',
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 2),
      );
    } finally {
      isMoving.value = false;
      _isProcessingMove = false;

      // Traiter le mouvement en attente
      if (_pendingMove != null) {
        final pending = _pendingMove!;
        _pendingMove = null;

        final currentPlayer = playerController.currentPlayer.value;
        if (currentPlayer != null) {
          final dx = pending.x - currentPlayer.position.x;
          final dy = pending.y - currentPlayer.position.y;

          // Petit délai pour éviter les mouvements trop rapides
          await Future.delayed(const Duration(milliseconds: 50));
          moveInDirection(dx, dy);
        }
      }
    }
  }

  // Méthodes de déplacement (4 directions seulement)
  Future<void> moveUp() async => moveInDirection(0, -1);
  Future<void> moveDown() async => moveInDirection(0, 1);
  Future<void> moveLeft() async => moveInDirection(-1, 0);
  Future<void> moveRight() async => moveInDirection(1, 0);

  // Forcer le rechargement complet
  void forceRefresh() {
    final player = playerController.currentPlayer.value;
    if (player != null) {
      worldController.refreshAllTiles();
      _gameService.revealTilesAround(player.position, player.id);
    }
  }

  @override
  void onReady() {
    super.onReady();

    // Vérification supplémentaire après 1 seconde
    Future.delayed(const Duration(seconds: 1), () {
      if (!isInitialized.value) {
        print('Réinitialisation après timeout...');
        _initializeGame();
      }
    });
  }
}
