import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/game_controller.dart';
import '../controllers/player_controller.dart';
import '../widgets/game_grid.dart';

class GameView extends GetView<GameController> {
  const GameView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        title: const Text('Flutter MMO'),
        backgroundColor: Colors.grey[850],
        actions: [
          Obx(() {
            final player = Get.find<PlayerController>().currentPlayer.value;
            if (player != null) {
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: Center(
                  child: Text(
                    'Position: (${player.position.x}, ${player.position.y})',
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          }),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: Obx(() {
                if (Get.find<PlayerController>().isLoading.value) {
                  return const CircularProgressIndicator();
                }
                return const GameGrid();
              }),
            ),
          ),
          _buildControls(),
        ],
      ),
    );
  }

  Widget _buildControls() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[850],
      child: Obx(() {
        final selectedPosition = controller.selectedPosition.value;
        final isMoving = controller.isMoving.value;

        if (selectedPosition != null) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: isMoving ? null : controller.confirmMove,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
                child: isMoving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text('Confirmer le déplacement'),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: isMoving ? null : controller.cancelSelection,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
                child: const Text('Annuler'),
              ),
            ],
          );
        }

        return const Text(
          'Cliquez sur une case adjacente pour vous déplacer',
          style: TextStyle(color: Colors.white70),
        );
      }),
    );
  }
}
