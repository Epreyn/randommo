// lib/app/modules/game/widgets/game_grid.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/models/position_model.dart';
import '../controllers/game_controller.dart';
import 'tile_widget.dart';

class GameGrid extends StatelessWidget {
  const GameGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<GameController>();

    // IMPORTANT : Utiliser GetBuilder pour détecter les update()
    return GetBuilder<GameController>(
      builder: (_) => Obx(() {
        if (controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
            ),
          );
        }

        final player = controller.currentPlayer.value;
        if (player == null) {
          return const Center(
            child: Text(
              'Erreur: Joueur non trouvé',
              style: TextStyle(color: Colors.white),
            ),
          );
        }

        final viewRadius = controller.viewRadius.value;
        final gridSize = viewRadius * 2 + 1;

        return Center(
          child: AspectRatio(
            aspectRatio: 1,
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.9,
                maxHeight: MediaQuery.of(context).size.height * 0.7,
              ),
              decoration: BoxDecoration(
                color: Colors.grey.shade900,
                border: Border.all(color: Colors.grey.shade700, width: 2),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  padding: EdgeInsets.zero,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: gridSize,
                    childAspectRatio: 1,
                    crossAxisSpacing: 0,
                    mainAxisSpacing: 0,
                  ),
                  itemCount: gridSize * gridSize,
                  itemBuilder: (context, index) {
                    final row = index ~/ gridSize;
                    final col = index % gridSize;

                    final position = Position(
                      x: player.position.x + col - viewRadius,
                      y: player.position.y + row - viewRadius,
                    );

                    final tile = controller.tiles[position.id];
                    final isRevealed =
                        controller.revealedTileIds.contains(position.id);
                    final isBeingRevealed =
                        controller.tilesBeingRevealed.contains(position.id);
                    final isPlayerPosition = position == player.position;

                    if (isBeingRevealed) {
                      print(
                          '🎯 GameGrid: Tuile ${position.id} est en cours d\'animation');
                    }

                    // Pendant le chargement initial, toutes les tuiles sont cachées
                    // sauf celles en cours d'animation
                    final shouldShowRevealed =
                        !controller.isInitialLoad.value &&
                            isRevealed &&
                            !isBeingRevealed;

                    return TileWidget(
                      key: ValueKey('tile_${position.id}'),
                      tile: tile,
                      position: position,
                      isRevealed: shouldShowRevealed,
                      isBeingRevealed: isBeingRevealed,
                      isPlayerPosition: isPlayerPosition,
                    );
                  },
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
