import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/position_model.dart';
import '../models/tile_model.dart';
import '../providers/firestore_provider.dart';

class WorldRepository {
  final CollectionReference _worldRef = FirestoreProvider.world;

  Future<Tile?> getTileAt(Position position) async {
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

  Future<void> createTile(Tile tile) async {
    try {
      await _worldRef.doc(tile.id).set(tile.toMap());
    } catch (e) {
      print('Erreur lors de la création de la tuile: $e');
    }
  }

  Future<List<Tile>> getTiles(List<String> tileIds) async {
    if (tileIds.isEmpty) return [];

    try {
      final chunks = <List<String>>[];
      for (var i = 0; i < tileIds.length; i += 10) {
        chunks.add(tileIds.sublist(i, i + 10 > tileIds.length ? tileIds.length : i + 10));
      }

      final tiles = <Tile>[];
      for (final chunk in chunks) {
        final snapshot = await _worldRef.where(FieldPath.documentId, whereIn: chunk).get();
        tiles.addAll(snapshot.docs.map((doc) => Tile.fromMap(doc.data() as Map<String, dynamic>)));
      }

      return tiles;
    } catch (e) {
      print('Erreur lors de la récupération des tuiles: $e');
      return [];
    }
  }

  Stream<List<Tile>> tilesInAreaStream(Position center, int radius) {
    final minX = center.x - radius;
    final maxX = center.x + radius;

    return _worldRef
        .where('position.x', isGreaterThanOrEqualTo: minX)
        .where('position.x', isLessThanOrEqualTo: maxX)
        .snapshots()
        .map((snapshot) {
      final tiles = snapshot.docs
          .map((doc) => Tile.fromMap(doc.data() as Map<String, dynamic>))
          .where((tile) {
        final dy = (tile.position.y - center.y).abs();
        return dy <= radius;
      }).toList();

      return tiles;
    });
  }
}
