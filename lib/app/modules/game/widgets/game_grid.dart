// lib/app/modules/game/widgets/game_grid.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/models/position_model.dart';
import '../controllers/game_controller.dart';
import '../controllers/player_controller.dart';
import '../controllers/world_controller.dart';
import 'tile_widget.dart';
import 'player_indicator_widget.dart';

class GameGrid extends StatefulWidget {
  const GameGrid({super.key});

  @override
  State<GameGrid> createState() => _GameGridState();
}

class _GameGridState extends State<GameGrid> {
  Position? _previousPlayerPosition;
  bool _isMoving = false;
  final Set<String> _newlyRevealedTiles = {};
  final Set<String> _previouslyRevealedTiles = {};

  @override
  void initState() {
    super.initState();
    // Initialiser avec les tuiles déjà révélées
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final worldController = Get.find<WorldController>();
      _previouslyRevealedTiles.addAll(worldController.revealedTileIds);
    });
  }

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

      // Détecter le changement de position
      if (_previousPlayerPosition != null &&
          _previousPlayerPosition != player.position &&
          !_isMoving) {
        _isMoving = true;

        // Sauvegarder les tuiles actuellement révélées
        _previouslyRevealedTiles.clear();
        _previouslyRevealedTiles.addAll(worldController.revealedTileIds);

        // Délai pour laisser l'animation du joueur se terminer avant de révéler les tuiles
        Future.delayed(const Duration(milliseconds: 250), () {
          if (mounted) {
            setState(() {
              _isMoving = false;

              // Identifier les nouvelles tuiles révélées
              _newlyRevealedTiles.clear();
              for (final tileId in worldController.revealedTileIds) {
                if (!_previouslyRevealedTiles.contains(tileId)) {
                  _newlyRevealedTiles.add(tileId);
                }
              }
            });
          }
        });
      }
      _previousPlayerPosition = player.position;

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
                      playerController, _isMoving),

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

                  // Indicateur de mouvement (sans texte)
                  if (gameController.isMoving.value)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
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
    bool isMoving,
  ) {
    return Stack(
      children: [
        // Grille des tuiles
        GridView.builder(
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
              final existsInDatabase =
                  worldController.isTileExistsInDatabase(position);

              // Vérifier les autres joueurs
              final hasOtherPlayer = playerController.nearbyPlayers
                  .any((p) => p.position == position);

              // Ne pas cacher les tuiles déjà révélées lors du mouvement
              final shouldReveal = isRevealed &&
                  (!isMoving || !_newlyRevealedTiles.contains(position.id));

              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child: TileWidget(
                  key: ValueKey('tile_${position.id}'),
                  tile: tile,
                  position: position,
                  isRevealed: shouldReveal,
                  isPlayerPosition: false, // On gère le joueur séparément
                  hasOtherPlayer: hasOtherPlayer,
                  existsInDatabase: existsInDatabase,
                ),
              );
            });
          },
        ),

        // Joueur animé par-dessus la grille
        LayoutBuilder(
          builder: (context, constraints) {
            // Calculer la taille exacte d'une tuile
            final gridWidth = constraints.maxWidth;
            final gridHeight = constraints.maxHeight;
            final tileWidth = gridWidth / gridSize;
            final tileHeight = gridHeight / gridSize;

            // Position centrale (le joueur est toujours au centre)
            final centerX = viewRadius * tileWidth;
            final centerY = viewRadius * tileHeight;

            return Positioned(
              left: centerX,
              top: centerY,
              width: tileWidth,
              height: tileHeight,
              child: Center(
                child: PlayerIndicatorWidget(
                  isMoving: _isMoving,
                  size: 32,
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
