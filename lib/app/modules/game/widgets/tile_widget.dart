import 'package:flutter/material.dart';
import '../../../data/models/tile_model.dart';
import '../../../data/models/position_model.dart';

class TileWidget extends StatelessWidget {
  final Tile? tile;
  final Position position;
  final bool isRevealed;
  final bool isPlayerPosition;
  final bool isSelected;
  final bool hasOtherPlayer;
  final VoidCallback onTap;

  const TileWidget({
    super.key,
    this.tile,
    required this.position,
    required this.isRevealed,
    required this.isPlayerPosition,
    required this.isSelected,
    required this.hasOtherPlayer,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.all(1),
        decoration: BoxDecoration(
          color: _getTileColor(),
          border: Border.all(
            color: isSelected ? Colors.yellow : Colors.black26,
            width: isSelected ? 3 : 1,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Stack(
          children: [
            if (!isRevealed)
              Container(
                color: Colors.black87,
                child: const Center(
                  child: Icon(
                    Icons.question_mark,
                    color: Colors.white54,
                    size: 20,
                  ),
                ),
              ),
            if (isPlayerPosition)
              const Center(
                child: Icon(
                  Icons.person,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            if (hasOtherPlayer && !isPlayerPosition)
              const Center(
                child: Icon(
                  Icons.person,
                  color: Colors.red,
                  size: 20,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _getTileColor() {
    if (!isRevealed) return Colors.grey[800]!;
    if (tile == null) return Colors.grey[600]!;

    switch (tile!.type) {
      case TileType.grass:
        return Colors.green[400]!;
      case TileType.water:
        return Colors.blue[400]!;
      case TileType.mountain:
        return Colors.brown[400]!;
    }
  }
}
