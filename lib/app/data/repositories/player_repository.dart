// lib/app/data/repositories/player_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/player_model.dart';
import '../models/position_model.dart';
import '../providers/firestore_provider.dart';

class PlayerRepository {
  final CollectionReference _playersRef = FirestoreProvider.players;

  Future<void> createPlayer(Player player) async {
    try {
      await _playersRef.doc(player.id).set(player.toMap());
    } catch (e) {
      print('Erreur lors de la création du joueur: $e');
    }
  }

  Future<Player?> getPlayer(String playerId) async {
    try {
      final doc = await _playersRef.doc(playerId).get();
      if (doc.exists) {
        return Player.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print('Erreur lors de la récupération du joueur: $e');
      return null;
    }
  }

  Future<void> updatePlayerPosition(String playerId, Position position) async {
    try {
      await _playersRef.doc(playerId).update({
        'position': position.toMap(),
        'lastActive': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Erreur lors de la mise à jour de la position: $e');
    }
  }

  Future<void> addRevealedTile(String playerId, String tileId) async {
    try {
      await _playersRef.doc(playerId).update({
        'revealedTiles': FieldValue.arrayUnion([tileId]),
      });
    } catch (e) {
      print('Erreur lors de l\'ajout de la tuile révélée: $e');
    }
  }

  Stream<Player?> playerStream(String playerId) {
    return _playersRef.doc(playerId).snapshots().map((doc) {
      if (doc.exists) {
        return Player.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    });
  }

  // Version simple sans index requis
  Stream<List<Player>> playersInAreaStream(Position center, int radius) {
    // Retourne une liste vide pour l'instant
    return Stream.value([]);
  }
}
