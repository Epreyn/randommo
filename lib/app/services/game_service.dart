// lib/app/services/game_service.dart
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/models/position_model.dart';
import '../data/models/tile_model.dart';
import '../data/repositories/world_repository.dart';
import '../data/repositories/player_repository.dart';
import 'world_generator_service.dart';

class GameService extends GetxService {
  final WorldRepository worldRepo = Get.find();
  final PlayerRepository playerRepo = Get.find();

  // Cache des tuiles pour éviter les lectures répétées
  final Map<String, Tile> _tileCache = {};

  // File d'attente pour les opérations batch
  final List<Tile> _pendingTileCreations = [];
  bool _batchInProgress = false;

  @override
  void onInit() {
    super.onInit();
    // Précharger la zone de spawn au démarrage
    _preloadSpawnArea();
  }

  Future<void> _preloadSpawnArea() async {
    // Précharger dans le générateur
    WorldGeneratorService.preloadArea(const Position(x: 0, y: 0), 10);

    // Charger les tuiles existantes depuis Firestore
    final positions = <String>[];
    for (int dx = -10; dx <= 10; dx++) {
      for (int dy = -10; dy <= 10; dy++) {
        positions.add('${dx}_$dy');
      }
    }

    try {
      final existingTiles = await worldRepo.getTiles(positions);
      for (final tile in existingTiles) {
        _tileCache[tile.id] = tile;
      }
    } catch (e) {
      print('Erreur préchargement spawn: $e');
    }
  }

  // Révèle les tuiles autour d'une position avec optimisation
  Future<List<Tile>> revealTilesAround(
      Position position, String playerId) async {
    final positions = WorldGeneratorService.getSurroundingPositions(position);
    final revealedTiles = <Tile>[];
    final newTiles = <Tile>[];
    final tileIdsToReveal = <String>[];

    // Phase 1: Vérification rapide et génération
    for (final pos in positions) {
      Tile? tile = _tileCache[pos.id];

      if (tile == null) {
        // Vérifier dans Firestore
        tile = await worldRepo.getTileAt(pos);

        if (tile == null) {
          // Générer nouvelle tuile
          tile = WorldGeneratorService.generateTile(pos, playerId);
          newTiles.add(tile);
        }

        _tileCache[pos.id] = tile;
      }

      revealedTiles.add(tile);
      tileIdsToReveal.add(pos.id);
    }

    // Phase 2: Sauvegarde batch des nouvelles tuiles
    if (newTiles.isNotEmpty) {
      _pendingTileCreations.addAll(newTiles);
      _processBatchCreations();
    }

    // Phase 3: Mise à jour des tuiles révélées du joueur (non bloquant)
    _updatePlayerRevealedTiles(playerId, tileIdsToReveal);

    return revealedTiles;
  }

  // Traitement batch des créations de tuiles
  Future<void> _processBatchCreations() async {
    if (_batchInProgress || _pendingTileCreations.isEmpty) return;

    _batchInProgress = true;

    try {
      // Copier et vider la liste
      final tilesToCreate = List<Tile>.from(_pendingTileCreations);
      _pendingTileCreations.clear();

      // Créer en batch
      final batch = FirebaseFirestore.instance.batch();
      final worldCollection = FirebaseFirestore.instance.collection('world');

      for (final tile in tilesToCreate) {
        batch.set(worldCollection.doc(tile.id), tile.toMap());
      }

      await batch.commit();
    } catch (e) {
      print('Erreur batch creation: $e');
    } finally {
      _batchInProgress = false;

      // Si d'autres tuiles en attente, relancer
      if (_pendingTileCreations.isNotEmpty) {
        Future.delayed(
            const Duration(milliseconds: 100), _processBatchCreations);
      }
    }
  }

  // Mise à jour asynchrone des tuiles révélées
  Future<void> _updatePlayerRevealedTiles(
      String playerId, List<String> tileIds) async {
    try {
      await FirebaseFirestore.instance
          .collection('players')
          .doc(playerId)
          .update({
        'revealedTiles': FieldValue.arrayUnion(tileIds),
      });
    } catch (e) {
      print('Erreur mise à jour tuiles révélées: $e');
    }
  }

  // Déplace un joueur avec vérification optimisée
  Future<bool> movePlayer(String playerId, Position from, Position to) async {
    if (!WorldGeneratorService.isValidMove(from, to)) {
      return false;
    }

    // Vérification rapide dans le cache
    Tile? destinationTile = _tileCache[to.id];

    if (destinationTile == null) {
      // Générer immédiatement si nécessaire
      destinationTile = WorldGeneratorService.generateTile(to, playerId);
      _tileCache[to.id] = destinationTile;

      // Ajouter à la file pour création
      _pendingTileCreations.add(destinationTile);
      _processBatchCreations();
    }

    if (!destinationTile.isWalkable) {
      return false;
    }

    // Démarrer les opérations en parallèle
    final updatePositionFuture = playerRepo.updatePlayerPosition(playerId, to);
    final revealTilesFuture = revealTilesAround(to, playerId);

    // Précharger la zone suivante
    WorldGeneratorService.preloadArea(to, 7);

    // Attendre les opérations critiques
    await updatePositionFuture;
    await revealTilesFuture;

    return true;
  }

  // Récupère une tuile avec cache
  Future<Tile?> getTileAt(Position position) async {
    if (_tileCache.containsKey(position.id)) {
      return _tileCache[position.id];
    }

    final tile = await worldRepo.getTileAt(position);
    if (tile != null) {
      _tileCache[position.id] = tile;
    }

    return tile;
  }

  // Précharge une zone complète
  Future<void> preloadArea(Position center, int radius) async {
    final positions = <String>[];

    for (int dx = -radius; dx <= radius; dx++) {
      for (int dy = -radius; dy <= radius; dy++) {
        final pos = Position(x: center.x + dx, y: center.y + dy);
        if (!_tileCache.containsKey(pos.id)) {
          positions.add(pos.id);
        }
      }
    }

    if (positions.isNotEmpty) {
      try {
        final tiles = await worldRepo.getTiles(positions);
        for (final tile in tiles) {
          _tileCache[tile.id] = tile;
        }
      } catch (e) {
        print('Erreur préchargement zone: $e');
      }
    }
  }

  // Nettoie le cache si nécessaire
  void clearCache() {
    _tileCache.clear();
    _pendingTileCreations.clear();
  }

  @override
  void onClose() {
    clearCache();
    super.onClose();
  }
}
