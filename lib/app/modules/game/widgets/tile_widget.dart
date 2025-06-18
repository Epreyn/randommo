// lib/app/modules/game/widgets/tile_widget.dart
import 'package:flutter/material.dart';
import '../../../data/models/tile_model.dart';
import '../../../data/models/position_model.dart';

class TileWidget extends StatelessWidget {
  final Tile? tile;
  final Position position;
  final bool isRevealed;
  final bool isPlayerPosition;
  final bool hasOtherPlayer;

  const TileWidget({
    super.key,
    this.tile,
    required this.position,
    required this.isRevealed,
    required this.isPlayerPosition,
    required this.hasOtherPlayer,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(0.5),
      decoration: BoxDecoration(
        color: _getTileColor(),
        border: Border.all(
          color: _getBorderColor(),
          width: isPlayerPosition ? 2.5 : 0.5,
        ),
        borderRadius: BorderRadius.circular(2),
        boxShadow: isPlayerPosition
            ? [
                BoxShadow(
                  color: Colors.yellow.withOpacity(0.5),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Pattern de texture selon le type
          if (tile != null) _buildTexturePattern(),

          // Effet de brouillard pour les bords non révélés
          if (!isRevealed && tile != null)
            Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.0,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.3),
                  ],
                ),
              ),
            ),

          // Indicateur du joueur principal
          if (isPlayerPosition) _buildPlayerIndicator(),

          // Autres joueurs
          if (hasOtherPlayer && !isPlayerPosition) _buildOtherPlayerIndicator(),
        ],
      ),
    );
  }

  Widget _buildTexturePattern() {
    switch (tile!.type) {
      case TileType.grass:
        return CustomPaint(
          painter: GrassPatternPainter(),
        );
      case TileType.water:
        return CustomPaint(
          painter: WaterPatternPainter(),
        );
      case TileType.mountain:
        return CustomPaint(
          painter: MountainPatternPainter(),
        );
    }
  }

  Widget _buildPlayerIndicator() {
    return Center(
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.green.shade700,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          Icons.person,
          color: Colors.green.shade700,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildOtherPlayerIndicator() {
    return Center(
      child: Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: const Icon(
          Icons.person,
          color: Colors.white,
          size: 16,
        ),
      ),
    );
  }

  Color _getTileColor() {
    // Si pas de tuile, gris foncé
    if (tile == null) {
      return Colors.grey.shade800;
    }

    // Afficher la couleur selon le type
    switch (tile!.type) {
      case TileType.grass:
        return isPlayerPosition ? Colors.green.shade500 : Colors.green.shade400;
      case TileType.water:
        return Colors.blue.shade400;
      case TileType.mountain:
        return Colors.brown.shade400;
    }
  }

  Color _getBorderColor() {
    if (isPlayerPosition) {
      return Colors.yellow;
    }

    if (tile == null) {
      return Colors.black26;
    }

    // Bordure plus sombre pour chaque type
    switch (tile!.type) {
      case TileType.grass:
        return Colors.green.shade600.withOpacity(0.3);
      case TileType.water:
        return Colors.blue.shade600.withOpacity(0.3);
      case TileType.mountain:
        return Colors.brown.shade600.withOpacity(0.3);
    }
  }
}

// Painters pour les textures
class GrassPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.green.shade500.withOpacity(0.2)
      ..style = PaintingStyle.fill;

    // Petits points pour simuler l'herbe
    for (int i = 0; i < 3; i++) {
      for (int j = 0; j < 3; j++) {
        canvas.drawCircle(
          Offset(size.width * (0.2 + i * 0.3), size.height * (0.2 + j * 0.3)),
          1.5,
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class WaterPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue.shade300.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Vagues
    canvas.drawArc(
      Rect.fromLTWH(0, size.height * 0.3, size.width, size.height * 0.3),
      0,
      3.14,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class MountainPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.brown.shade300.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    // Triangle pour la montagne
    final path = Path()
      ..moveTo(size.width * 0.5, size.height * 0.3)
      ..lineTo(size.width * 0.3, size.height * 0.7)
      ..lineTo(size.width * 0.7, size.height * 0.7)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
