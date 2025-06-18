import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreProvider {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static CollectionReference get players => _firestore.collection('players');
  static CollectionReference get world => _firestore.collection('world');

  static CollectionReference playerRevealedTiles(String playerId) {
    return players.doc(playerId).collection('revealed_tiles');
  }
}
