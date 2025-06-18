import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/game_controller.dart';
import '../controllers/player_controller.dart';
import '../widgets/game_grid.dart';
import '../widgets/directional_pad.dart';

class GameView extends GetView<GameController> {
  const GameView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        title: const Text('RandoMmo'),
        backgroundColor: Colors.grey[850],
        actions: [
          Obx(() {
            final player = Get.find<PlayerController>().currentPlayer.value;
            if (player != null) {
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        player.name,
                        style: const TextStyle(fontSize: 12),
                      ),
                      Text(
                        'Position: (${player.position.x}, ${player.position.y})',
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          }),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 600) {
              return Column(
                children: [
                  Expanded(
                    flex: 3,
                    child: Center(
                      child: Obx(() {
                        if (Get.find<PlayerController>().isLoading.value) {
                          return const CircularProgressIndicator();
                        }
                        return const GameGrid();
                      }),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(20),
                    color: Colors.grey[850],
                    child: const Center(
                      child: DirectionalPad(),
                    ),
                  ),
                ],
              );
            } else {
              return Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Center(
                      child: Obx(() {
                        if (Get.find<PlayerController>().isLoading.value) {
                          return const CircularProgressIndicator();
                        }
                        return const GameGrid();
                      }),
                    ),
                  ),
                  Container(
                    width: 300,
                    color: Colors.grey[850],
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Contrôles',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 30),
                        const DirectionalPad(),
                        const SizedBox(height: 30),
                        _buildLegend(),
                      ],
                    ),
                  ),
                ],
              );
            }
          },
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Légende:',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          _legendItem(Colors.green[400]!, 'Herbe (praticable)'),
          _legendItem(Colors.blue[400]!, 'Eau (impraticable)'),
          _legendItem(Colors.brown[400]!, 'Montagne (impraticable)'),
          _legendItem(Colors.grey[800]!, 'Non exploré'),
        ],
      ),
    );
  }

  Widget _legendItem(Color color, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.black26),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
