// lib/app/modules/game/controllers/player_controller.dart
import 'package:get/get.dart';
import '../../../data/models/player_model.dart';
import '../../../data/models/position_model.dart';
import '../../../data/repositories/player_repository.dart';
import '../../../services/auth_service.dart';
import '../../../services/game_service.dart';

class PlayerController extends GetxController {
  final PlayerRepository _playerRepo = Get.find();
  final AuthService _authService = Get.find();

  final Rxn<Player> currentPlayer = Rxn<Player>();
  final RxList<Player> nearbyPlayers = <Player>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isFirstTime = false.obs;

  // Cache pour éviter les mises à jour trop fréquentes
  DateTime? _lastPositionUpdate;
  static const _minUpdateInterval = Duration(milliseconds: 200);

  @override
  void onInit() {
    super.onInit();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    isLoading.value = true;

    final userId = _authService.currentUserId;
    if (userId == null) {
      print('Erreur: Pas d\'utilisateur connecté');
      isLoading.value = false;
      return;
    }

    try {
      // Vérifier si le joueur existe
      Player? player = await _playerRepo.getPlayer(userId);

      if (player == null) {
        isFirstTime.value = true;
        print('Création d\'un nouveau joueur...');

        // Créer un nouveau joueur
        player = Player(
          id: userId,
          name: 'Player_${userId.substring(0, 6)}',
          position: const Position(x: 0, y: 0),
          revealedTiles: [], // Vide au départ
          lastActive: DateTime.now(),
        );

        await _playerRepo.createPlayer(player);

        // Révéler immédiatement les tuiles de spawn
        final gameService = Get.find<GameService>();
        await gameService.revealTilesAround(player.position, player.id);

        // Recharger pour avoir les tuiles révélées
        await Future.delayed(const Duration(milliseconds: 500));
        player = await _playerRepo.getPlayer(userId);

        print(
            'Nouveau joueur créé avec ${player?.revealedTiles.length ?? 0} tuiles révélées');
      } else {
        print('Joueur existant chargé: ${player.name}');
        print('Tuiles révélées: ${player.revealedTiles.length}');
      }

      // Mettre à jour immédiatement
      currentPlayer.value = player;

      // Écouter les changements avec debounce
      _setupPlayerStream(userId);

      // Pour les nouveaux joueurs, forcer une révélation supplémentaire
      if (isFirstTime.value && player != null) {
        final gameService = Get.find<GameService>();
        await gameService.revealTilesAround(player.position, player.id);
      }
    } catch (e) {
      print('Erreur lors de l\'initialisation du joueur: $e');
      Get.snackbar(
        'Erreur',
        'Impossible de charger le joueur',
        snackPosition: SnackPosition.TOP,
      );
    } finally {
      isLoading.value = false;
    }
  }

  void _setupPlayerStream(String userId) {
    _playerRepo.playerStream(userId).listen(
      (updatedPlayer) {
        if (updatedPlayer != null) {
          // Éviter les mises à jour trop fréquentes
          final now = DateTime.now();
          if (_lastPositionUpdate != null &&
              now.difference(_lastPositionUpdate!) < _minUpdateInterval) {
            return;
          }

          _lastPositionUpdate = now;
          currentPlayer.value = updatedPlayer;

          // Décommenter quand l'index sera créé
          // _watchNearbyPlayers(updatedPlayer.position);
        }
      },
      onError: (error) {
        print('Erreur stream joueur: $error');
      },
    );
  }

  // Pour plus tard quand l'index Firestore sera créé
  void _watchNearbyPlayers(Position center) {
    // _playerRepo.playersInAreaStream(center, 10).listen(
    //   (players) {
    //     nearbyPlayers.value = players
    //         .where((p) => p.id != currentPlayer.value?.id)
    //         .toList();
    //   },
    //   onError: (error) {
    //     print('Erreur stream joueurs proches: $error');
    //   },
    // );
  }

  Future<bool> moveToPosition(Position newPosition) async {
    final player = currentPlayer.value;
    if (player == null) return false;

    try {
      final gameService = Get.find<GameService>();
      final success =
          await gameService.movePlayer(player.id, player.position, newPosition);

      if (success) {
        // Mettre à jour localement immédiatement pour la réactivité
        currentPlayer.value = player.copyWith(
          position: newPosition,
          lastActive: DateTime.now(),
        );

        // Recharger depuis Firestore pour synchroniser
        Future.delayed(const Duration(milliseconds: 500), () async {
          final updatedPlayer = await _playerRepo.getPlayer(player.id);
          if (updatedPlayer != null) {
            currentPlayer.value = updatedPlayer;
          }
        });
      }

      return success;
    } catch (e) {
      print('Erreur lors du déplacement: $e');
      return false;
    }
  }

  // Forcer le rechargement du joueur
  Future<void> refreshPlayer() async {
    final userId = _authService.currentUserId;
    if (userId != null) {
      final player = await _playerRepo.getPlayer(userId);
      if (player != null) {
        currentPlayer.value = player;
      }
    }
  }

  @override
  void onClose() {
    nearbyPlayers.clear();
    super.onClose();
  }
}
