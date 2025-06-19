// lib/app/modules/game/widgets/animated_game_grid.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/models/position_model.dart';
import '../controllers/game_controller.dart';
import '../controllers/player_controller.dart';
import '../controllers/world_controller.dart';
import 'tile_widget.dart';
import 'player_indicator_widget.dart';

class AnimatedGameGrid extends StatefulWidget {
  const AnimatedGameGrid({super.key});

  @override
  State<AnimatedGameGrid> createState() => _AnimatedGameGridState();
}

class _AnimatedGameGridState extends State<AnimatedGameGrid>
    with SingleTickerProviderStateMixin {
  late AnimationController _moveController;

  Position? _lastPosition;
  double _offsetX = 0;
  double _offsetY = 0;

  Set<String> _previousRevealedTiles = {};
  Set<String> _animatingTiles = {};

  @override
  void initState() {
    super.initState();
    _moveController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _moveController.dispose();
    super.dispose();
  }

  Future<void> _animateMovement(Position from, Position to) async {
    // Direction opposée pour l'animation de la grille
    _offsetX = -(to.x - from.x).toDouble();
    _offsetY = -(to.y - from.y).toDouble();

    setState(() {});

    // Animer
    _moveController.forward(from: 0).then((_) {
      setState(() {
        _offsetX = 0;
        _offsetY = 0;
      });
      _moveController.reset();

      // Gérer les nouvelles tuiles
      _checkForNewTiles();
    });
  }

  void _checkForNewTiles() {
    final worldController = Get.find<WorldController>();
    final currentTiles = Set<String>.from(worldController.revealedTileIds);
    final newTiles = currentTiles.difference(_previousRevealedTiles);

    if (newTiles.isNotEmpty) {
      setState(() {
        _animatingTiles = Set.from(newTiles);
      });

      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _animatingTiles.clear();
          });
        }
      });
    }

    _previousRevealedTiles = currentTiles;
  }

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

      // Détecter le changement
      if (_lastPosition != null && _lastPosition != player.position) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _animateMovement(_lastPosition!, player.position);
        });
      } else if (_lastPosition == null) {
        _previousRevealedTiles =
            Set<String>.from(worldController.revealedTileIds);
      }

      _lastPosition = player.position;

      final viewRadius = worldController.viewRadius.value;
      final visibleSize = viewRadius * 2 + 1;
      final totalSize = visibleSize + 2; // Une case de plus de chaque côté

      return Center(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final containerSize = constraints.maxWidth < constraints.maxHeight
                ? constraints.maxWidth * 0.9
                : constraints.maxHeight * 0.7;
            final tileSize = containerSize / visibleSize;

            return Container(
              width: containerSize,
              height: containerSize,
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
                    // Grille avec overflow caché
                    AnimatedBuilder(
                      animation: _moveController,
                      builder: (context, child) {
                        final progress =
                            Curves.easeInOut.transform(_moveController.value);
                        final currentOffsetX =
                            _offsetX * (1 - progress) * tileSize;
                        final currentOffsetY =
                            _offsetY * (1 - progress) * tileSize;

                        return Transform.translate(
                          // Décaler pour centrer la grille étendue
                          offset: Offset(
                            currentOffsetX - tileSize,
                            currentOffsetY - tileSize,
                          ),
                          child: SizedBox(
                            width: totalSize * tileSize,
                            height: totalSize * tileSize,
                            child: GridView.builder(
                              physics: const NeverScrollableScrollPhysics(),
                              padding: EdgeInsets.zero,
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: totalSize,
                                childAspectRatio: 1,
                                crossAxisSpacing: 0,
                                mainAxisSpacing: 0,
                              ),
                              itemCount: totalSize * totalSize,
                              itemBuilder: (context, index) {
                                final row = index ~/ totalSize;
                                final col = index % totalSize;

                                // Position avec le décalage pour la bordure
                                final position = Position(
                                  x: player.position.x + col - viewRadius - 1,
                                  y: player.position.y + row - viewRadius - 1,
                                );

                                final tile =
                                    worldController.getTileAt(position);
                                final isRevealed =
                                    worldController.isTileRevealed(position);
                                final existsInDatabase = worldController
                                    .isTileExistsInDatabase(position);
                                final shouldAnimate =
                                    _animatingTiles.contains(position.id);

                                // Délai d'animation
                                final dx =
                                    (position.x - player.position.x).abs();
                                final dy =
                                    (position.y - player.position.y).abs();
                                final distance = dx + dy;
                                final delay = (distance * 100).clamp(0, 500);

                                return TileWidget(
                                  key: ValueKey('tile_${position.id}'),
                                  tile: tile,
                                  position: position,
                                  isRevealed: isRevealed && !shouldAnimate,
                                  isPlayerPosition: false,
                                  hasOtherPlayer: false,
                                  existsInDatabase: existsInDatabase,
                                  shouldAnimate: shouldAnimate && isRevealed,
                                  animationDelay: delay,
                                );
                              },
                            ),
                          ),
                        );
                      },
                    ),

                    // Joueur au centre
                    Center(
                      child: PlayerIndicatorWidget(
                        isMoving: gameController.isMoving.value,
                        size: 32,
                      ),
                    ),

                    // Overlay de chargement
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
                                    color: Colors.white, fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      );
    });
  }
}
