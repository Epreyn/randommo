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
  final RxSet<String> existingTileIds =
      <String>{}.obs; // Tuiles qui existent en BDD

  // Cache local pour performance
  final Map<String, Tile> _tileCache = {};
  final Map<String, bool> _loadingTiles = {};
  final Map<String, bool> _existsInDatabase = {};

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

    // Charger une zone légèrement plus grande pour le déplacement de la grille
    final extendedRadius = viewRadius.value + 1;

    // Calculer toutes les positions visibles (avec marge)
    for (int dx = -extendedRadius; dx <= extendedRadius; dx++) {
      for (int dy = -extendedRadius; dy <= extendedRadius; dy++) {
        final pos = Position(x: center.x + dx, y: center.y + dy);

        // Si la tuile est révélée, on peut la charger
        if (isTileRevealed(pos)) {
          // Si dans le cache, utiliser directement
          if (_tileCache.containsKey(pos.id)) {
            newVisibleTiles[pos.id] = _tileCache[pos.id]!;
          } else {
            // NE PAS générer de tuile temporaire ici
            // Marquer pour chargement depuis Firestore
            if (!_loadingTiles.containsKey(pos.id)) {
              tilesToLoad.add(pos);
            }
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

    // Vérifier aussi l'existence des tuiles non révélées dans la zone visible étendue
    _checkTilesExistence(center);
  }

  // Vérifier l'existence des tuiles non révélées pour l'affichage gris/noir
  Future<void> _checkTilesExistence(Position center) async {
    final positions = <Position>[];
    final extendedRadius =
        viewRadius.value + 1; // Zone étendue pour le déplacement

    for (int dx = -extendedRadius; dx <= extendedRadius; dx++) {
      for (int dy = -extendedRadius; dy <= extendedRadius; dy++) {
        final pos = Position(x: center.x + dx, y: center.y + dy);

        // Si pas déjà vérifié et pas révélé
        if (!_existsInDatabase.containsKey(pos.id) && !isTileRevealed(pos)) {
          positions.add(pos);
        }
      }
    }

    // Vérifier en batch
    if (positions.isNotEmpty) {
      try {
        final tileIds = positions.map((p) => p.id).toList();
        final existingTiles = await _worldRepo.getTiles(tileIds);

        // Marquer celles qui existent
        for (final tile in existingTiles) {
          _existsInDatabase[tile.id] = true;
          existingTileIds.add(tile.id);
        }

        // Marquer celles qui n'existent pas
        for (final pos in positions) {
          if (!existingTileIds.contains(pos.id)) {
            _existsInDatabase[pos.id] = false;
          }
        }
      } catch (e) {
        print('Erreur vérification existence: $e');
      }
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
          // Marquer comme existant en BDD
          _existsInDatabase[pos.id] = true;
          existingTileIds.add(pos.id);

          // Enregistrer dans le générateur pour éviter la régénération
          WorldGeneratorService.registerExistingTile(pos, firestoreTile.type);

          // Remplacer la tuile temporaire par la vraie
          _tileCache[pos.id] = firestoreTile;

          // Mettre à jour si toujours visible
          if (visibleTiles.containsKey(pos.id)) {
            visibleTiles[pos.id] = firestoreTile;
          }
        } else {
          // La tuile n'existe pas en BDD
          _existsInDatabase[pos.id] = false;
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

  bool isTileExistsInDatabase(Position position) {
    return _existsInDatabase[position.id] ?? false;
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
