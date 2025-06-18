import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/models/position_model.dart';
import '../controllers/game_controller.dart';
import '../controllers/player_controller.dart';
import '../controllers/world_controller.dart';
import 'tile_widget.dart';

class GameGrid extends StatelessWidget {
  const GameGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final gameController = Get.find<GameController>();
    final playerController = Get.find<PlayerController>();
    final worldController = Get.find<WorldController>();

    return Obx(() {
      final player = playerController.currentPlayer.value;
      if (player == null) {
        return const Center(child: CircularProgressIndicator());
      }

      final viewRadius = worldController.viewRadius.value;
      final gridSize = viewRadius * 2 + 1;

      return Center(
        child: AspectRatio(
          aspectRatio: 1,
          child: Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.9,
              maxHeight: MediaQuery.of(context).size.height * 0.7,
            ),
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: gridSize,
                childAspectRatio: 1,
              ),
              itemCount: gridSize * gridSize,
              itemBuilder: (context, index) {
                final row = index ~/ gridSize;
                final col = index % gridSize;

                final position = Position(
                  x: player.position.x + col - viewRadius,
                  y: player.position.y + row - viewRadius,
                );

                final tile = worldController.getTileAt(position);
                final isRevealed = worldController.isTileRevealed(position);
                final isPlayerPosition = position == player.position;
                final isSelected = gameController.selectedPosition.value == position;

                final hasOtherPlayer = playerController.nearbyPlayers
                    .any((p) => p.position == position);

                return TileWidget(
                  tile: tile,
                  position: position,
                  isRevealed: isRevealed,
                  isPlayerPosition: isPlayerPosition,
                  isSelected: isSelected,
                  hasOtherPlayer: hasOtherPlayer,
                  onTap: () => gameController.selectTile(position),
                );
              },
            ),
          ),
        ),
      );
    });
  }
}
