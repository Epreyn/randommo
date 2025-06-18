import 'package:get/get.dart';
import '../../../data/models/position_model.dart';
import '../../../services/game_service.dart';
import '../../../services/world_generator_service.dart';
import 'player_controller.dart';
import 'world_controller.dart';

class GameController extends GetxController {
  final GameService _gameService = Get.find();
  final PlayerController playerController = Get.find();
  final WorldController worldController = Get.find();

  final RxBool isMoving = false.obs;
  final Rxn<Position> selectedPosition = Rxn<Position>();

  @override
  void onInit() {
    super.onInit();
    _initializeGame();
  }

  Future<void> _initializeGame() async {
    final player = playerController.currentPlayer.value;
    if (player != null) {
      await _gameService.revealTilesAround(player.position, player.id);
    }
  }

  void selectTile(Position position) {
    final player = playerController.currentPlayer.value;
    if (player == null || isMoving.value) return;

    if (!worldController.isTileVisible(position)) return;

    if (WorldGeneratorService.isValidMove(player.position, position)) {
      selectedPosition.value = position;
    }
  }

  Future<void> confirmMove() async {
    final targetPosition = selectedPosition.value;
    if (targetPosition == null || isMoving.value) return;

    isMoving.value = true;

    final success = await playerController.moveToPosition(targetPosition);

    if (success) {
      selectedPosition.value = null;
    } else {
      Get.snackbar(
        'Mouvement impossible',
        'Cette case n\'est pas accessible',
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 2),
      );
    }

    isMoving.value = false;
  }

  void cancelSelection() {
    selectedPosition.value = null;
  }
}
