import 'package:get/get.dart';
import '../data/models/position_model.dart';
import '../data/models/tile_model.dart';
import '../data/repositories/world_repository.dart';
import '../data/repositories/player_repository.dart';
import 'world_generator_service.dart';

class GameService extends GetxService {
  final WorldRepository worldRepo = Get.find();
  final PlayerRepository playerRepo = Get.find();

  Future<List<Tile>> revealTilesAround(Position position, String playerId) async {
    final positions = WorldGeneratorService.getSurroundingPositions(position);
    final revealedTiles = <Tile>[];

    for (final pos in positions) {
      Tile? existingTile = await worldRepo.getTileAt(pos);

      if (existingTile == null) {
        final newTile = WorldGeneratorService.generateTile(pos, playerId);
        await worldRepo.createTile(newTile);
        existingTile = newTile;
      }

      revealedTiles.add(existingTile);

      await playerRepo.addRevealedTile(playerId, pos.id);
    }

    return revealedTiles;
  }

  Future<bool> movePlayer(String playerId, Position from, Position to) async {
    if (!WorldGeneratorService.isValidMove(from, to)) {
      return false;
    }

    final destinationTile = await worldRepo.getTileAt(to);
    if (destinationTile == null || !destinationTile.isWalkable) {
      return false;
    }

    await playerRepo.updatePlayerPosition(playerId, to);

    await revealTilesAround(to, playerId);

    return true;
  }
}
