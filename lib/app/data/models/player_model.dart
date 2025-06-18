import 'position_model.dart';

class Player {
  final String id;
  final String name;
  final Position position;
  final List<String> revealedTiles;
  final DateTime lastActive;

  Player({
    required this.id,
    required this.name,
    required this.position,
    required this.revealedTiles,
    required this.lastActive,
  });

  factory Player.fromMap(Map<String, dynamic> map) {
    return Player(
      id: map['id'] ?? '',
      name: map['name'] ?? 'Unknown',
      position: Position.fromMap(map['position']),
      revealedTiles: List<String>.from(map['revealedTiles'] ?? []),
      lastActive: DateTime.parse(map['lastActive']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'position': position.toMap(),
      'revealedTiles': revealedTiles,
      'lastActive': lastActive.toIso8601String(),
    };
  }

  Player copyWith({
    String? id,
    String? name,
    Position? position,
    List<String>? revealedTiles,
    DateTime? lastActive,
  }) {
    return Player(
      id: id ?? this.id,
      name: name ?? this.name,
      position: position ?? this.position,
      revealedTiles: revealedTiles ?? this.revealedTiles,
      lastActive: lastActive ?? this.lastActive,
    );
  }
}
