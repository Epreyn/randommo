// lib/app/modules/game/controllers/world_controller.dart
import 'package:get/get.dart';
import '../../../data/models/tile_model.dart';
import '../../../data/models/position_model.dart';
import '../../../data/models/player_model.dart';
import '../../../data/repositories/world_repository.dart';
import '../../../services/world_generator_service.dart';
import 'player_controller.dart';

class WorldController extends GetxController {
  final WorldRepository _worldRepo = Get.find();
  final PlayerController _playerController = Get.find();

  // Observable pour la réactivité
  final RxMap<String, Tile> visibleTiles = <String, Tile>{}.obs;
  final RxInt viewRadius = 5.obs;
  final RxSet<String> revealedTileIds = <String>{}.obs;

  // Cache local pour performance
  final Map<String, Tile> _tileCache = {};
  final Map<String, bool> _loadingTiles = {};

  @override
  void onInit() {
    super.onInit();
    _setupWorldStream();

    // Précharger la zone de spawn
    WorldGeneratorService.preloadArea(const Position(x: 0, y: 0), 10);
  }

  void _setupWorldStream() {
    // Écouter les changements du joueur
    ever(_playerController.currentPlayer, (Player? player) {
      if (player != null) {
        // Mettre à jour les tuiles révélées
        revealedTileIds.value = player.revealedTiles.toSet();

        // Précharger la zone autour du joueur pour la cohérence
        WorldGeneratorService.preloadArea(
            player.position, viewRadius.value + 3);

        // Mettre à jour immédiatement les tuiles visibles
        _updateVisibleTilesInstant(player.position);
      }
    });
  }

  // Mise à jour instantanée des tuiles visibles
  void _updateVisibleTilesInstant(Position center) {
    final newVisibleTiles = <String, Tile>{};
    final tilesToLoad = <Position>[];

    // Calculer toutes les positions visibles
    for (int dx = -viewRadius.value; dx <= viewRadius.value; dx++) {
      for (int dy = -viewRadius.value; dy <= viewRadius.value; dy++) {
        final pos = Position(x: center.x + dx, y: center.y + dy);

        // Si dans le cache, utiliser directement
        if (_tileCache.containsKey(pos.id)) {
          newVisibleTiles[pos.id] = _tileCache[pos.id]!;
        } else {
          // Générer immédiatement une tuile temporaire pour l'affichage
          final tempTile = WorldGeneratorService.generateTile(
              pos, _playerController.currentPlayer.value?.id ?? 'system');
          newVisibleTiles[pos.id] = tempTile;
          _tileCache[pos.id] = tempTile;

          // Marquer pour chargement depuis Firestore
          if (!_loadingTiles.containsKey(pos.id)) {
            tilesToLoad.add(pos);
          }
        }
      }
    }

    // Mettre à jour immédiatement l'affichage
    visibleTiles.value = newVisibleTiles;

    // Charger depuis Firestore en arrière-plan
    if (tilesToLoad.isNotEmpty) {
      _loadTilesFromFirestore(tilesToLoad);
    }
  }

  // Chargement asynchrone depuis Firestore
  Future<void> _loadTilesFromFirestore(List<Position> positions) async {
    for (final pos in positions) {
      if (_loadingTiles[pos.id] == true) continue;

      _loadingTiles[pos.id] = true;

      try {
        final firestoreTile = await _worldRepo.getTileAt(pos);

        if (firestoreTile != null) {
          // Remplacer la tuile temporaire par la vraie
          _tileCache[pos.id] = firestoreTile;

          // Mettre à jour si toujours visible
          if (visibleTiles.containsKey(pos.id)) {
            visibleTiles[pos.id] = firestoreTile;
          }
        }
      } catch (e) {
        print('Erreur chargement tuile ${pos.id}: $e');
      } finally {
        _loadingTiles.remove(pos.id);
      }
    }
  }

  // Récupère une tuile (depuis le cache ou génère)
  Tile? getTileAt(Position position) {
    // D'abord vérifier les tuiles visibles (observable)
    if (visibleTiles.containsKey(position.id)) {
      return visibleTiles[position.id];
    }

    // Puis le cache
    if (_tileCache.containsKey(position.id)) {
      return _tileCache[position.id];
    }

    // Générer si nécessaire
    final player = _playerController.currentPlayer.value;
    if (player != null && isTileVisible(position)) {
      final tile = WorldGeneratorService.generateTile(position, player.id);
      _tileCache[position.id] = tile;
      return tile;
    }

    return null;
  }

  bool isTileRevealed(Position position) {
    return revealedTileIds.contains(position.id);
  }

  bool isTileVisible(Position position) {
    final player = _playerController.currentPlayer.value;
    if (player == null) return false;

    final dx = (position.x - player.position.x).abs();
    final dy = (position.y - player.position.y).abs();

    return dx <= viewRadius.value && dy <= viewRadius.value;
  }

  // Force le rechargement de toutes les tuiles visibles
  void refreshAllTiles() {
    final player = _playerController.currentPlayer.value;
    if (player != null) {
      _updateVisibleTilesInstant(player.position);
    }
  }

  // Précharge une zone pour améliorer les performances
  void preloadArea(Position center, int radius) {
    WorldGeneratorService.preloadArea(center, radius);

    // Charger aussi depuis Firestore si possible
    final positions = <Position>[];
    for (int dx = -radius; dx <= radius; dx++) {
      for (int dy = -radius; dy <= radius; dy++) {
        positions.add(Position(x: center.x + dx, y: center.y + dy));
      }
    }

    _loadTilesFromFirestore(positions);
  }

  @override
  void onClose() {
    _tileCache.clear();
    _loadingTiles.clear();
    super.onClose();
  }
}
