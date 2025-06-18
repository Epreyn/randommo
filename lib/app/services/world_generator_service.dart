import 'dart:math';
import '../data/models/position_model.dart';
import '../data/models/tile_model.dart';

class WorldGeneratorService {
  static final Random _random = Random();

  static Tile generateTile(Position position, String createdBy) {
    final tileId = '${position.x}_${position.y}';

    final typeRandom = _random.nextDouble();
    TileType type;

    if (typeRandom < 0.6) {
      type = TileType.grass;
    } else if (typeRandom < 0.85) {
      type = TileType.water;
    } else {
      type = TileType.mountain;
    }

    return Tile(
      id: tileId,
      position: position,
      type: type,
      createdAt: DateTime.now(),
      createdBy: createdBy,
    );
  }

  static List<Position> getSurroundingPositions(Position center) {
    final positions = <Position>[];

    for (int dx = -1; dx <= 1; dx++) {
      for (int dy = -1; dy <= 1; dy++) {
        positions.add(Position(
          x: center.x + dx,
          y: center.y + dy,
        ));
      }
    }

    return positions;
  }

  static double getDistance(Position a, Position b) {
    return sqrt(pow(a.x - b.x, 2) + pow(a.y - b.y, 2));
  }

  static bool isValidMove(Position from, Position to) {
    final dx = (from.x - to.x).abs();
    final dy = (from.y - to.y).abs();

    return dx <= 1 && dy <= 1 && (dx != 0 || dy != 0);
  }
}
