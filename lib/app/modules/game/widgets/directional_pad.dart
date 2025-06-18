import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/game_controller.dart';

class DirectionalPad extends StatelessWidget {
  const DirectionalPad({super.key});

  @override
  Widget build(BuildContext context) {
    final GameController controller = Get.find();

    return Container(
      width: 200,
      height: 200,
      child: Stack(
        children: [
          Positioned(
            top: 0,
            left: 60,
            child: _DirectionalButton(
              onPressed: controller.moveUp,
              icon: Icons.arrow_upward,
            ),
          ),
          Positioned(
            top: 60,
            left: 0,
            child: _DirectionalButton(
              onPressed: controller.moveLeft,
              icon: Icons.arrow_back,
            ),
          ),
          Positioned(
            top: 60,
            left: 60,
            child: SizedBox(
              width: 80,
              height: 80,
              child: Center(
                child: Obx(
                  () => controller.isMoving.value
                      ? const SizedBox(
                          width: 30,
                          height: 30,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.green),
                          ),
                        )
                      : SizedBox.shrink(),
                ),
              ),
            ),
          ),
          Positioned(
            top: 60,
            right: 0,
            child: _DirectionalButton(
              onPressed: controller.moveRight,
              icon: Icons.arrow_forward,
            ),
          ),
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
  final double size;

  const _DirectionalButton({
    required this.onPressed,
    required this.icon,
    this.size = 80,
  });

  @override
  Widget build(BuildContext context) {
    final GameController controller = Get.find();

    return Obx(() => SizedBox(
          width: size,
          height: size,
          child: ElevatedButton(
            onPressed: controller.isMoving.value ? null : onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey[700],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(size / 2),
              ),
              padding: EdgeInsets.zero,
              elevation: 4,
            ),
            child: Icon(
              icon,
              size: size * 0.4,
            ),
          ),
        ));
  }
}
