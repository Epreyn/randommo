// lib/app/modules/game/widgets/directional_pad.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/game_controller.dart';

class DirectionalPad extends StatelessWidget {
  const DirectionalPad({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<GameController>();

    return SizedBox(
      width: 200,
      height: 200,
      child: Stack(
        children: [
          // Bouton Haut
          Positioned(
            top: 0,
            left: 60,
            child: _DirectionalButton(
              onPressed: controller.moveUp,
              icon: Icons.arrow_upward,
            ),
          ),
          // Bouton Gauche
          Positioned(
            top: 60,
            left: 0,
            child: _DirectionalButton(
              onPressed: controller.moveLeft,
              icon: Icons.arrow_back,
            ),
          ),
          // Centre avec indicateur de mouvement
          Positioned(
            top: 60,
            left: 60,
            child: SizedBox(
              width: 80,
              height: 80,
              child: Center(
                child: Obx(() => controller.isMoving.value
                    ? const SizedBox(
                        width: 30,
                        height: 30,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.green),
                        ),
                      )
                    : Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.grey[800],
                          shape: BoxShape.circle,
                          border:
                              Border.all(color: Colors.grey[600]!, width: 2),
                        ),
                      )),
              ),
            ),
          ),
          // Bouton Droite
          Positioned(
            top: 60,
            right: 0,
            child: _DirectionalButton(
              onPressed: controller.moveRight,
              icon: Icons.arrow_forward,
            ),
          ),
          // Bouton Bas
          Positioned(
            bottom: 0,
            left: 60,
            child: _DirectionalButton(
              onPressed: controller.moveDown,
              icon: Icons.arrow_downward,
            ),
          ),
        ],
      ),
    );
  }
}

class _DirectionalButton extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData icon;

  const _DirectionalButton({
    required this.onPressed,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<GameController>();

    return Obx(() => SizedBox(
          width: 80,
          height: 80,
          child: ElevatedButton(
            onPressed: controller.isMoving.value ? null : onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey[700],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(40),
              ),
              padding: EdgeInsets.zero,
              elevation: 4,
              disabledBackgroundColor: Colors.grey[800],
            ),
            child: Icon(icon, size: 32),
          ),
        ));
  }
}
