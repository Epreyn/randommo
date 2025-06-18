import 'position_model.dart';

enum TileType { grass, water, mountain }

class Tile {
  final String id;
  final Position position;
  final TileType type;
  final DateTime createdAt;
  final String? createdBy;

  Tile({
    required this.id,
    required this.position,
    required this.type,
    required this.createdAt,
    this.createdBy,
  });

  factory Tile.fromMap(Map<String, dynamic> map) {
    return Tile(
      id: map['id'] ?? '',
      position: Position.fromMap(map['position']),
      type: TileType.values.firstWhere(
        (e) => e.toString() == 'TileType.${map['type']}',
        orElse: () => TileType.grass,
      ),
      createdAt: DateTime.parse(map['createdAt']),
      createdBy: map['createdBy'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'position': position.toMap(),
      'type': type.toString().split('.').last,
      'createdAt': createdAt.toIso8601String(),
      'createdBy': createdBy,
    };
  }

  bool get isWalkable => type == TileType.grass;
}
