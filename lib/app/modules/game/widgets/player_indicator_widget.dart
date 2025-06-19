// lib/app/modules/game/widgets/player_indicator_widget.dart
import 'package:flutter/material.dart';

class PlayerIndicatorWidget extends StatelessWidget {
  final bool isMoving;
  final double size;

  const PlayerIndicatorWidget({
    super.key,
    this.isMoving = false,
    this.size = 32,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 300),
      tween: Tween<double>(
        begin: 0,
        end: isMoving ? 1 : 0,
      ),
      builder: (context, animationValue, child) {
        return Transform.translate(
          offset: Offset(0, -10 * animationValue), // Effet de saut
          child: Transform.scale(
            scale: 1 + (0.15 * animationValue), // Légère augmentation de taille
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    Colors.white,
                    Colors.green.shade50,
                  ],
                  stops: const [0.7, 1.0],
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.green.shade700,
                  width: 2.5,
                ),
                boxShadow: [
                  // Ombre principale
                  BoxShadow(
                    color: Colors.black.withOpacity(0.4),
                    blurRadius: 6 + (4 * animationValue),
                    offset: Offset(0, 3 + (5 * animationValue)),
                  ),
                  // Lueur verte lors du mouvement
                  if (animationValue > 0)
                    BoxShadow(
                      color: Colors.green.withOpacity(0.3 * animationValue),
                      blurRadius: 15,
                      spreadRadius: 3,
                    ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    Icons.person,
                    color: Colors.green.shade700,
                    size: size * 0.7,
                  ),
                  // Cercle de mouvement
                  if (animationValue > 0)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: size * (1 + animationValue * 0.5),
                      height: size * (1 + animationValue * 0.5),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.green
                              .withOpacity(0.3 * (1 - animationValue)),
                          width: 2,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
