// lib/app/data/repositories/world_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/position_model.dart';
import '../models/tile_model.dart';
import '../providers/firestore_provider.dart';

class WorldRepository {
  final CollectionReference _worldRef = FirestoreProvider.world;

  // Cache des requêtes en cours pour éviter les doublons
  final Map<String, Future<Tile?>> _pendingRequests = {};

  // Récupère une tuile à une position donnée avec cache de requêtes
  Future<Tile?> getTileAt(Position position) async {
    final tileId = position.id;

    // Si une requête est déjà en cours pour cette tuile, attendre son résultat
    if (_pendingRequests.containsKey(tileId)) {
      return _pendingRequests[tileId];
    }

    // Créer la requête
    final future = _getTileAtInternal(position);
    _pendingRequests[tileId] = future;

    try {
      final result = await future;
      return result;
    } finally {
      // Nettoyer la requête en cours
      _pendingRequests.remove(tileId);
    }
  }

  Future<Tile?> _getTileAtInternal(Position position) async {
    try {
      final doc = await _worldRef.doc(position.id).get();
      if (doc.exists) {
        return Tile.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print('Erreur lors de la récupération de la tuile: $e');
      return null;
    }
  }

  // Crée une nouvelle tuile
  Future<void> createTile(Tile tile) async {
    try {
      await _worldRef.doc(tile.id).set(tile.toMap());
    } catch (e) {
      print('Erreur lors de la création de la tuile: $e');
    }
  }

  // Version optimisée pour récupérer plusieurs tuiles
  Future<List<Tile>> getTiles(List<String> tileIds) async {
    if (tileIds.isEmpty) return [];

    try {
      // Limiter à 10 IDs par requête (limite Firestore)
      final tiles = <Tile>[];
      final uniqueIds = tileIds.toSet().toList(); // Éviter les doublons

      // Traiter par lots de 10
      for (var i = 0; i < uniqueIds.length; i += 10) {
        final batch = uniqueIds.sublist(
            i, i + 10 > uniqueIds.length ? uniqueIds.length : i + 10);

        final snapshot =
            await _worldRef.where(FieldPath.documentId, whereIn: batch).get();

        tiles.addAll(snapshot.docs
            .map((doc) => Tile.fromMap(doc.data() as Map<String, dynamic>)));
      }

      return tiles;
    } catch (e) {
      print('Erreur lors de la récupération des tuiles: $e');
      return [];
    }
  }

  // Stream optimisé pour les tuiles dans une zone
  Stream<List<Tile>> tilesInAreaStream(Position center, int radius) {
    final minX = center.x - radius;
    final maxX = center.x + radius;

    // Utiliser snapshots avec métadonnées pour détecter le cache
    return _worldRef
        .where('position.x', isGreaterThanOrEqualTo: minX)
        .where('position.x', isLessThanOrEqualTo: maxX)
        .snapshots(
            includeMetadataChanges:
                false) // Ignorer les changements de métadonnées
        .map((snapshot) {
      // Si les données viennent du cache, traiter plus rapidement
      if (snapshot.metadata.isFromCache) {
        print('Données depuis le cache Firestore');
      }

      final tiles = snapshot.docs
          .map((doc) => Tile.fromMap(doc.data() as Map<String, dynamic>))
          .where((tile) {
        final dy = (tile.position.y - center.y).abs();
        return dy <= radius;
      }).toList();

      return tiles;
    });
  }

  // Créer plusieurs tuiles en batch
  Future<void> createTilesBatch(List<Tile> tiles) async {
    if (tiles.isEmpty) return;

    final batch = FirebaseFirestore.instance.batch();

    for (final tile in tiles) {
      batch.set(_worldRef.doc(tile.id), tile.toMap());
    }

    try {
      await batch.commit();
    } catch (e) {
      print('Erreur lors de la création batch des tuiles: $e');
    }
  }
}
