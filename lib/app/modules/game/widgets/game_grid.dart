// lib/app/modules/game/widgets/game_grid.dart
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
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                'Chargement du joueur...',
                style: TextStyle(color: Colors.white70),
              ),
            ],
          ),
        );
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
              child: Stack(
                children: [
                  // Grille principale
                  _buildMainGrid(gridSize, viewRadius, player, worldController,
                      playerController),

                  // Overlay de chargement si initialisation
                  if (!gameController.isInitialized.value)
                    Container(
                      color: Colors.black54,
                      child: const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.green),
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Génération du monde...',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Indicateur de mouvement
                  if (gameController.isMoving.value)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Déplacement...',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildMainGrid(
    int gridSize,
    int viewRadius,
    player,
    WorldController worldController,
    PlayerController playerController,
  ) {
    return GridView.builder(
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

        // Chaque tuile dans un Obx pour la réactivité
        return Obx(() {
          // Récupérer les données réactives
          final tile = worldController.getTileAt(position);
          final isRevealed = worldController.isTileRevealed(position);
          final isPlayerPosition = position == player.position;

          // Vérifier les autres joueurs
          final hasOtherPlayer =
              playerController.nearbyPlayers.any((p) => p.position == position);

          // Debug pour les tuiles au nord du joueur
          if (position.x == player.position.x &&
              position.y == player.position.y - 1) {
            debugPrint('Tuile nord: tile=${tile?.type}, revealed=$isRevealed');
          }

          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: TileWidget(
              key: ValueKey('tile_${position.id}_${tile?.type}'),
              tile: tile,
              position: position,
              isRevealed: isRevealed,
              isPlayerPosition: isPlayerPosition,
              hasOtherPlayer: hasOtherPlayer,
            ),
          );
        });
      },
    );
  }
}

// Widget d'information sur la tuile (optionnel)
class TileInfoOverlay extends StatelessWidget {
  final Position position;
  final String? tileType;

  const TileInfoOverlay({
    super.key,
    required this.position,
    this.tileType,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '${position.x},${position.y}${tileType != null ? '\n$tileType' : ''}',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 8,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
