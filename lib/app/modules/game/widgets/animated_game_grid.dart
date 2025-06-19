// // lib/app/modules/game/widgets/animated_game_grid.dart
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import '../../../data/models/position_model.dart';
// import '../controllers/game_controller.dart';
// import '../controllers/player_controller.dart';
// import '../controllers/world_controller.dart';
// import 'tile_widget.dart';
// import 'player_indicator_widget.dart';

// class AnimatedGameGrid extends StatefulWidget {
//   const AnimatedGameGrid({super.key});

//   @override
//   State<AnimatedGameGrid> createState() => _AnimatedGameGridState();
// }

// class _AnimatedGameGridState extends State<AnimatedGameGrid>
//     with SingleTickerProviderStateMixin {
//   late AnimationController _animationController;
//   late Animation<double> _animation;

//   Position? _lastPlayerPosition;
//   double _animationOffsetX = 0;
//   double _animationOffsetY = 0;

//   Set<String> _previousRevealedTiles = {};
//   Set<String> _tilesToAnimate = {};

//   // Nombre de tuiles supplémentaires de chaque côté pour éviter les zones vides
//   static const int _extraTiles = 3;

//   @override
//   void initState() {
//     super.initState();
//     _animationController = AnimationController(
//       duration: const Duration(milliseconds: 450),
//       vsync: this,
//     );

//     _animation = CurvedAnimation(
//       parent: _animationController,
//       curve: Curves.easeInOutQuad,
//     );

//     _animation.addListener(() {
//       setState(() {});
//     });
//   }

//   @override
//   void dispose() {
//     _animationController.dispose();
//     super.dispose();
//   }

//   void _handleMovement(Position from, Position to) async {
//     // Calculer le décalage (inversé pour la grille)
//     final dx = -(to.x - from.x).toDouble();
//     final dy = -(to.y - from.y).toDouble();

//     // Définir l'animation
//     _animationOffsetX = dx;
//     _animationOffsetY = dy;

//     // Démarrer l'animation
//     await _animationController.forward(from: 0);

//     // Une fois l'animation terminée
//     setState(() {
//       _animationOffsetX = 0;
//       _animationOffsetY = 0;
//       _animationController.reset();
//     });

//     // Gérer les nouvelles tuiles après le mouvement
//     final worldController = Get.find<WorldController>();
//     final currentTiles = Set<String>.from(worldController.revealedTileIds);
//     final newTiles = currentTiles.difference(_previousRevealedTiles);

//     if (newTiles.isNotEmpty) {
//       setState(() {
//         _tilesToAnimate = Set.from(newTiles);
//       });

//       // Nettoyer après les animations
//       Future.delayed(const Duration(seconds: 2), () {
//         if (mounted) {
//           setState(() {
//             _tilesToAnimate.clear();
//           });
//         }
//       });
//     }

//     _previousRevealedTiles = currentTiles;
//   }

//   @override
//   Widget build(BuildContext context) {
//     final gameController = Get.find<GameController>();
//     final playerController = Get.find<PlayerController>();
//     final worldController = Get.find<WorldController>();

//     return Obx(() {
//       final player = playerController.currentPlayer.value;
//       if (player == null) {
//         return const Center(child: CircularProgressIndicator());
//       }

//       // Détecter le changement de position
//       if (_lastPlayerPosition != null &&
//           _lastPlayerPosition != player.position) {
//         WidgetsBinding.instance.addPostFrameCallback((_) {
//           _handleMovement(_lastPlayerPosition!, player.position);
//         });
//       } else if (_lastPlayerPosition == null) {
//         _previousRevealedTiles =
//             Set<String>.from(worldController.revealedTileIds);
//       }

//       _lastPlayerPosition = player.position;

//       final viewRadius = worldController.viewRadius.value;
//       final visibleGridSize = viewRadius * 2 + 1;
//       final totalGridSize = visibleGridSize + (_extraTiles * 2);

//       return Center(
//         child: LayoutBuilder(
//           builder: (context, constraints) {
//             final size = constraints.maxWidth < constraints.maxHeight
//                 ? constraints.maxWidth * 0.9
//                 : constraints.maxHeight * 0.7;
//             final tileSize = size / visibleGridSize;

//             return Container(
//               width: size,
//               height: size,
//               decoration: BoxDecoration(
//                 color: Colors.grey.shade900,
//                 border: Border.all(color: Colors.grey.shade700, width: 2),
//                 borderRadius: BorderRadius.circular(8),
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.black.withOpacity(0.5),
//                     blurRadius: 10,
//                     offset: const Offset(0, 4),
//                   ),
//                 ],
//               ),
//               child: ClipRRect(
//                 borderRadius: BorderRadius.circular(6),
//                 child: Stack(
//                   children: [
//                     // Grille avec ClipRect et OverflowBox
//                     ClipRect(
//                       child: OverflowBox(
//                         maxWidth: size + (tileSize * _extraTiles * 2),
//                         maxHeight: size + (tileSize * _extraTiles * 2),
//                         child: Transform.translate(
//                           offset: Offset(
//                             _animationOffsetX *
//                                 (1 - _animation.value) *
//                                 tileSize,
//                             _animationOffsetY *
//                                 (1 - _animation.value) *
//                                 tileSize,
//                           ),
//                           child: Container(
//                             width: tileSize * totalGridSize,
//                             height: tileSize * totalGridSize,
//                             child: GridView.builder(
//                               physics: const NeverScrollableScrollPhysics(),
//                               padding: EdgeInsets.zero,
//                               gridDelegate:
//                                   SliverGridDelegateWithFixedCrossAxisCount(
//                                 crossAxisCount: totalGridSize,
//                                 childAspectRatio: 1,
//                                 crossAxisSpacing: 0,
//                                 mainAxisSpacing: 0,
//                               ),
//                               itemCount: totalGridSize * totalGridSize,
//                               itemBuilder: (context, index) {
//                                 final row = index ~/ totalGridSize;
//                                 final col = index % totalGridSize;

//                                 // Position dans la grille étendue
//                                 // Les tuiles supplémentaires sont autour, donc on ajuste l'index
//                                 final adjustedCol = col - _extraTiles;
//                                 final adjustedRow = row - _extraTiles;

//                                 final position = Position(
//                                   x: player.position.x +
//                                       adjustedCol -
//                                       viewRadius,
//                                   y: player.position.y +
//                                       adjustedRow -
//                                       viewRadius,
//                                 );

//                                 final tile =
//                                     worldController.getTileAt(position);
//                                 final isRevealed =
//                                     worldController.isTileRevealed(position);
//                                 final existsInDatabase = worldController
//                                     .isTileExistsInDatabase(position);
//                                 final shouldAnimate =
//                                     _tilesToAnimate.contains(position.id);

//                                 // Calculer le délai d'animation
//                                 final dx =
//                                     (position.x - player.position.x).abs();
//                                 final dy =
//                                     (position.y - player.position.y).abs();
//                                 final distance = dx + dy;
//                                 final animationDelay =
//                                     (distance * 80).clamp(0, 400);

//                                 return TileWidget(
//                                   key: ValueKey('tile_${position.id}'),
//                                   tile: tile,
//                                   position: position,
//                                   isRevealed: isRevealed && !shouldAnimate,
//                                   isPlayerPosition: false,
//                                   hasOtherPlayer: false,
//                                   existsInDatabase: existsInDatabase,
//                                   shouldAnimate: shouldAnimate && isRevealed,
//                                   animationDelay: animationDelay,
//                                 );
//                               },
//                             ),
//                           ),
//                         ),
//                       ),
//                     ),

//                     // Joueur au centre
//                     Center(
//                       child: PlayerIndicatorWidget(
//                         isMoving: gameController.isMoving.value,
//                         size: 32,
//                       ),
//                     ),

//                     // Overlay de chargement
//                     if (!gameController.isInitialized.value)
//                       Container(
//                         color: Colors.black54,
//                         child: const Center(
//                           child: Column(
//                             mainAxisAlignment: MainAxisAlignment.center,
//                             children: [
//                               CircularProgressIndicator(
//                                 valueColor:
//                                     AlwaysStoppedAnimation<Color>(Colors.green),
//                               ),
//                               SizedBox(height: 16),
//                               Text(
//                                 'Génération du monde...',
//                                 style: TextStyle(
//                                     color: Colors.white, fontSize: 16),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ),
//                   ],
//                 ),
//               ),
//             );
//           },
//         ),
//       );
//     });
//   }
// }
