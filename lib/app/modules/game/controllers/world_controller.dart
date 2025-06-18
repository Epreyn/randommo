import 'package:get/get.dart';
import '../../../data/models/tile_model.dart';
import '../../../data/models/position_model.dart';
import '../../../data/repositories/world_repository.dart';
import '../../../data/models/player_model.dart';
import 'player_controller.dart';

class WorldController extends GetxController {
  final WorldRepository _worldRepo = Get.find();
  final PlayerController _playerController = Get.find();

  final RxMap<String, Tile> visibleTiles = <String, Tile>{}.obs;
  final RxInt viewRadius = 5.obs;

  @override
  void onInit() {
    super.onInit();
    _setupWorldStream();
  }

  void _setupWorldStream() {
    ever(_playerController.currentPlayer, (Player? player) {
      if (player != null) {
        _updateVisibleTiles(player.position);
      }
    });
  }

  void _updateVisibleTiles(Position center) {
    _worldRepo.tilesInAreaStream(center, viewRadius.value).listen((tiles) {
      visibleTiles.clear();
      for (final tile in tiles) {
        visibleTiles[tile.id] = tile;
      }
    });
  }

  Tile? getTileAt(Position position) {
    return visibleTiles[position.id];
  }

  bool isTileRevealed(Position position) {
    final player = _playerController.currentPlayer.value;
    if (player == null) return false;

    return player.revealedTiles.contains(position.id);
  }

  bool isTileVisible(Position position) {
    final player = _playerController.currentPlayer.value;
    if (player == null) return false;

    final dx = (position.x - player.position.x).abs();
    final dy = (position.y - player.position.y).abs();

    return dx <= viewRadius.value && dy <= viewRadius.value;
  }
}
