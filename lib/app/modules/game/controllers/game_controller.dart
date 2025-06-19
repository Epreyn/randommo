// lib/app/modules/game/controllers/game_controller.dart
import 'dart:async';
import 'dart:math';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../data/models/position_model.dart';
import '../../../data/models/tile_model.dart';
import '../../../data/models/player_model.dart';
import '../../../services/auth_service.dart';

class GameController extends GetxController {
  final AuthService _authService = Get.find();

  // Observables
  final Rxn<Player> currentPlayer = Rxn<Player>();
  final RxMap<String, Tile> tiles = <String, Tile>{}.obs;
  final RxSet<String> revealedTileIds = <String>{}.obs;
  final RxBool isLoading = true.obs;
  final RxBool isMoving = false.obs;
  final RxInt viewRadius = 5.obs;

  // Animation state
  final RxList<String> tilesBeingRevealed = <String>[].obs;
  final RxBool isInitialLoad = true.obs;

  @override
  void onInit() {
    super.onInit();
    _initializeGame();
  }

  Future<void> _initializeGame() async {
    isLoading.value = true;
    print('🎮 Initialisation du jeu...');

    final userId = _authService.currentUserId;
    if (userId == null) {
      print('❌ Erreur: Pas d\'utilisateur connecté');
      isLoading.value = false;
      return;
    }

    try {
      // 1. Charger le joueur depuis Firebase
      final playerDoc = await FirebaseFirestore.instance
          .collection('players')
          .doc(userId)
          .get();

      if (!playerDoc.exists) {
        print('👤 Création d\'un nouveau joueur');
        // Créer un nouveau joueur
        await _createNewPlayer(userId);
      } else {
        print('👤 Chargement du joueur existant');
        // Charger le joueur existant
        currentPlayer.value = Player.fromMap(playerDoc.data()!);
        revealedTileIds.value = currentPlayer.value!.revealedTiles.toSet();

        print('📊 Tuiles révélées: ${revealedTileIds.length}');

        // 2. Charger les tuiles révélées depuis Firebase
        await _loadRevealedTiles();
      }
    } catch (e) {
      print('❌ Erreur lors de l\'initialisation: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _createNewPlayer(String userId) async {
    final player = Player(
      id: userId,
      name: 'Player_${userId.substring(0, 6)}',
      position: const Position(x: 0, y: 0),
      revealedTiles: [],
      lastActive: DateTime.now(),
    );

    await FirebaseFirestore.instance
        .collection('players')
        .doc(userId)
        .set(player.toMap());

    currentPlayer.value = player;

    // Révéler les tuiles de spawn
    await _revealTilesAround(player.position);

    // Recharger le joueur pour avoir les tuiles révélées mises à jour
    final updatedDoc = await FirebaseFirestore.instance
        .collection('players')
        .doc(userId)
        .get();

    if (updatedDoc.exists) {
      currentPlayer.value = Player.fromMap(updatedDoc.data()!);
      revealedTileIds.value = currentPlayer.value!.revealedTiles.toSet();

      // Charger les tuiles révélées
      await _loadRevealedTiles();
    }
  }

  Future<void> _loadRevealedTiles() async {
    if (revealedTileIds.isEmpty) {
      print('❌ Aucune tuile révélée à charger');
      return;
    }

    print('📥 Chargement de ${revealedTileIds.length} tuiles révélées');

    // Charger les tuiles par batch
    final batches = <List<String>>[];
    final tileIdsList = revealedTileIds.toList();

    for (var i = 0; i < tileIdsList.length; i += 10) {
      final end = (i + 10 < tileIdsList.length) ? i + 10 : tileIdsList.length;
      batches.add(tileIdsList.sublist(i, end));
    }

    for (final batch in batches) {
      final snapshot = await FirebaseFirestore.instance
          .collection('world')
          .where(FieldPath.documentId, whereIn: batch)
          .get();

      for (final doc in snapshot.docs) {
        final tile = Tile.fromMap(doc.data());
        tiles[tile.id] = tile;
      }
    }

    print('✅ ${tiles.length} tuiles chargées dans le cache');

    // Animer la révélation des tuiles
    _animateTileReveal();
  }

  void _animateTileReveal() {
    if (currentPlayer.value == null || !isInitialLoad.value) return;

    print('🎬 Début animation - ${revealedTileIds.length} tuiles à révéler');

    final center = currentPlayer.value!.position;

    // Créer une liste de toutes les tuiles avec leur distance
    final tilesWithDistance = <MapEntry<String, int>>[];

    for (final tileId in revealedTileIds) {
      final pos = _parsePosition(tileId);
      final distance = (pos.x - center.x).abs() + (pos.y - center.y).abs();
      tilesWithDistance.add(MapEntry(tileId, distance));
    }

    // Trier par distance
    tilesWithDistance.sort((a, b) => a.value.compareTo(b.value));

    // Animer chaque tuile avec un délai basé sur sa distance
    for (int i = 0; i < tilesWithDistance.length; i++) {
      final tile = tilesWithDistance[i];
      final delay = tile.value * 150; // Délai basé sur la distance

      Timer(Duration(milliseconds: delay), () {
        print('🌊 Animation de ${tile.key} (distance ${tile.value})');

        // Ajouter UNE SEULE tuile à la fois
        if (!tilesBeingRevealed.contains(tile.key)) {
          // Force complètement une nouvelle liste
          tilesBeingRevealed.value = [...tilesBeingRevealed, tile.key];

          // Forcer la mise à jour
          tilesBeingRevealed.refresh();
          update();
        }

        // La retirer après l'animation
        Timer(const Duration(milliseconds: 700), () {
          print('✅ Fin animation de ${tile.key}');

          // Retirer en créant une nouvelle liste
          final newList =
              tilesBeingRevealed.where((id) => id != tile.key).toList();
          tilesBeingRevealed.value = newList;

          // Forcer la mise à jour
          tilesBeingRevealed.refresh();
          update();
        });
      });
    }

    // Fin du chargement
    final maxDelay = tilesWithDistance.isEmpty
        ? 0
        : tilesWithDistance.last.value * 150 + 800;
    Timer(Duration(milliseconds: maxDelay), () {
      print('🏁 Fin du chargement initial');
      isInitialLoad.value = false;
    });
  }

  Position _parsePosition(String tileId) {
    final parts = tileId.split('_');
    return Position(x: int.parse(parts[0]), y: int.parse(parts[1]));
  }

  Future<void> movePlayer(int dx, int dy) async {
    if (isMoving.value || currentPlayer.value == null) return;

    final from = currentPlayer.value!.position;
    final to = Position(x: from.x + dx, y: from.y + dy);

    // Vérifier si le mouvement est valide
    if ((dx.abs() == 1 && dy == 0) || (dx == 0 && dy.abs() == 1)) {
      isMoving.value = true;

      try {
        // Vérifier ou générer la tuile de destination
        Tile? destinationTile = tiles[to.id];

        if (destinationTile == null) {
          // Vérifier dans Firebase d'abord
          final tileDoc = await FirebaseFirestore.instance
              .collection('world')
              .doc(to.id)
              .get();

          if (tileDoc.exists) {
            destinationTile = Tile.fromMap(tileDoc.data()!);
          } else {
            // Générer une nouvelle tuile simplement
            destinationTile = _generateSimpleTile(to);

            // Sauvegarder dans Firebase
            await FirebaseFirestore.instance
                .collection('world')
                .doc(to.id)
                .set(destinationTile.toMap());
          }

          tiles[to.id] = destinationTile;
        }

        // Vérifier si praticable
        if (!destinationTile.isWalkable) {
          Get.snackbar(
            'Mouvement impossible',
            'Cette case n\'est pas accessible',
            snackPosition: SnackPosition.TOP,
            duration: const Duration(seconds: 1),
          );
          return;
        }

        // Mettre à jour la position
        currentPlayer.update((player) {
          player?.position = to;
          player?.lastActive = DateTime.now();
        });

        // Sauvegarder dans Firebase
        await FirebaseFirestore.instance
            .collection('players')
            .doc(currentPlayer.value!.id)
            .update({
          'position': to.toMap(),
          'lastActive': DateTime.now().toIso8601String(),
        });

        // Révéler les nouvelles tuiles
        await _revealTilesAround(to);
      } catch (e) {
        print('Erreur lors du déplacement: $e');
      } finally {
        isMoving.value = false;
      }
    }
  }

  Future<void> _revealTilesAround(Position center) async {
    print('🔍 Révélation des tuiles autour de ${center.id}');

    final positions = [
      center,
      Position(x: center.x, y: center.y - 1),
      Position(x: center.x + 1, y: center.y),
      Position(x: center.x, y: center.y + 1),
      Position(x: center.x - 1, y: center.y),
    ];

    final newTileIds = <String>[];
    final tilesToCreate = <Tile>[];

    for (final pos in positions) {
      if (!revealedTileIds.contains(pos.id)) {
        newTileIds.add(pos.id);

        // Vérifier si la tuile existe déjà
        if (!tiles.containsKey(pos.id)) {
          final tileDoc = await FirebaseFirestore.instance
              .collection('world')
              .doc(pos.id)
              .get();

          if (tileDoc.exists) {
            tiles[pos.id] = Tile.fromMap(tileDoc.data()!);
          } else {
            // Générer une nouvelle tuile
            final tile = _generateSimpleTile(pos);
            tiles[pos.id] = tile;
            tilesToCreate.add(tile);
          }
        }
      }
    }

    print('📝 Nouvelles tuiles à révéler: ${newTileIds.join(", ")}');

    // Créer les nouvelles tuiles en batch
    if (tilesToCreate.isNotEmpty) {
      final batch = FirebaseFirestore.instance.batch();
      for (final tile in tilesToCreate) {
        batch.set(FirebaseFirestore.instance.collection('world').doc(tile.id),
            tile.toMap());
      }
      await batch.commit();
      print('💾 ${tilesToCreate.length} nouvelles tuiles créées');
    }

    // Mettre à jour les tuiles révélées
    if (newTileIds.isNotEmpty) {
      revealedTileIds.addAll(newTileIds);

      await FirebaseFirestore.instance
          .collection('players')
          .doc(currentPlayer.value!.id)
          .update({
        'revealedTiles': FieldValue.arrayUnion(newTileIds),
      });

      print('✅ Tuiles révélées mises à jour dans Firebase');

      // Animer la révélation seulement si pas en chargement initial
      if (!isInitialLoad.value) {
        // Créer une nouvelle liste pour l'animation
        final animList = List<String>.from(tilesBeingRevealed);
        animList.addAll(newTileIds);
        tilesBeingRevealed.value = animList;

        // Retirer après l'animation
        Future.delayed(const Duration(milliseconds: 600), () {
          final cleanList = List<String>.from(tilesBeingRevealed);
          cleanList.removeWhere((id) => newTileIds.contains(id));
          tilesBeingRevealed.value = cleanList;
        });
      }
    }
  }

  // Méthodes de déplacement
  void moveUp() => movePlayer(0, -1);
  void moveDown() => movePlayer(0, 1);
  void moveLeft() => movePlayer(-1, 0);
  void moveRight() => movePlayer(1, 0);

  // Méthode de test pour débugger l'animation
  void testRevealAnimation() {
    print('🧪 TEST: Animation manuelle');
    final testTiles = ['0_-1', '1_0', '0_1', '-1_0'];

    // IMPORTANT : Remplacer directement la liste
    tilesBeingRevealed.value = List<String>.from(testTiles);

    Timer(const Duration(seconds: 2), () {
      tilesBeingRevealed.value = [];
      print('🧪 TEST: Animation terminée');
    });
  }

  // Génération simple de tuiles
  Tile _generateSimpleTile(Position position) {
    final random = Random();
    final roll = random.nextDouble();

    TileType type;
    if (roll < 0.15) {
      type = TileType.water;
    } else if (roll < 0.25) {
      type = TileType.mountain;
    } else {
      type = TileType.grass;
    }

    return Tile(
      id: position.id,
      position: position,
      type: type,
      createdAt: DateTime.now(),
      createdBy: currentPlayer.value?.id,
    );
  }

  void testSingleTile() {
    print('🧪 TEST: Animation d\'une seule tuile');

    // Tester avec une seule tuile
    tilesBeingRevealed.value = ['0_-1'];
    tilesBeingRevealed.refresh();
    update();

    print('État de tilesBeingRevealed: ${tilesBeingRevealed.value}');

    Timer(const Duration(seconds: 2), () {
      tilesBeingRevealed.value = [];
      tilesBeingRevealed.refresh();
      update();
      print('🧪 TEST terminé');
    });
  }
}
