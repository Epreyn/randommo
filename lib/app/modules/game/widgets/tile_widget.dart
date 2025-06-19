// lib/app/modules/game/widgets/tile_widget.dart
import 'package:flutter/material.dart';
import '../../../data/models/tile_model.dart';
import '../../../data/models/position_model.dart';

class TileWidget extends StatefulWidget {
  final Tile? tile;
  final Position position;
  final bool isRevealed;
  final bool isBeingRevealed;
  final bool isPlayerPosition;

  const TileWidget({
    super.key,
    this.tile,
    required this.position,
    required this.isRevealed,
    required this.isBeingRevealed,
    required this.isPlayerPosition,
  });

  @override
  State<TileWidget> createState() => _TileWidgetState();
}

class _TileWidgetState extends State<TileWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _flipAnimation;
  late Animation<double> _scaleAnimation;
  bool _animationCompleted = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _animationCompleted = true;
        });
      }
    });

    _flipAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.9),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.9, end: 1.1),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.1, end: 1.0),
        weight: 40,
      ),
    ]).animate(_controller);

    // Démarrer l'animation si la tuile est en cours de révélation
    if (widget.isBeingRevealed) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(TileWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Log pour debug
    if (oldWidget.isBeingRevealed != widget.isBeingRevealed) {
      print(
          '🔄 TileWidget ${widget.position.id}: isBeingRevealed ${oldWidget.isBeingRevealed} → ${widget.isBeingRevealed}');
    }

    // Démarrer l'animation quand isBeingRevealed passe à true
    if (!oldWidget.isBeingRevealed && widget.isBeingRevealed) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Si l'animation est terminée, afficher directement la tuile révélée
    if (_animationCompleted) {
      return _buildRevealedTile();
    }

    // Si la tuile est en cours d'animation
    if (widget.isBeingRevealed &&
        (_controller.isAnimating || _controller.value > 0)) {
      return AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final isShowingBack = _flipAnimation.value < 0.5;
          final rotationAngle = _flipAnimation.value * 3.14159;

          Widget content;
          if (isShowingBack) {
            content = _buildHiddenTile();
          } else {
            content = Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()..rotateY(3.14159),
              child: _buildRevealedTile(),
            );
          }

          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.002)
              ..rotateY(rotationAngle)
              ..scale(_scaleAnimation.value),
            child: content,
          );
        },
      );
    }

    // Si la tuile est révélée (après le chargement initial)
    if (widget.isRevealed) {
      return _buildRevealedTile();
    }

    // Par défaut, afficher la tuile cachée
    return _buildHiddenTile();
  }

  Widget _buildHiddenTile() {
    return Container(
      margin: const EdgeInsets.all(0.5),
      decoration: BoxDecoration(
        color: Colors.black87,
        border: Border.all(color: Colors.grey.shade800, width: 1),
      ),
    );
  }

  Widget _buildRevealedTile() {
    if (widget.tile == null) {
      return Container(
        margin: const EdgeInsets.all(0.5),
        decoration: BoxDecoration(
          color: Colors.grey.shade800,
          border: Border.all(color: Colors.grey.shade700, width: 1),
        ),
        child: const Center(
          child: Icon(
            Icons.generating_tokens,
            color: Colors.grey,
            size: 16,
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.all(0.5),
      decoration: BoxDecoration(
        color: _getTileColor(),
        border: Border.all(
          color: widget.isPlayerPosition ? Colors.yellow : _getBorderColor(),
          width: widget.isPlayerPosition ? 2 : 1,
        ),
      ),
      child: Stack(
        children: [
          if (widget.tile != null) _buildTextureOverlay(),
          if (widget.isPlayerPosition) _buildPlayerIndicator(),
        ],
      ),
    );
  }

  Widget _buildTextureOverlay() {
    switch (widget.tile!.type) {
      case TileType.grass:
        return Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.topLeft,
              radius: 1.5,
              colors: [
                Colors.green.shade300.withOpacity(0.2),
                Colors.transparent,
              ],
            ),
          ),
        );
      case TileType.water:
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.blue.shade200.withOpacity(0.3),
                Colors.transparent,
                Colors.blue.shade200.withOpacity(0.3),
              ],
            ),
          ),
        );
      case TileType.mountain:
        return Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 0.8,
              colors: [
                Colors.brown.shade300.withOpacity(0.3),
                Colors.transparent,
              ],
            ),
          ),
        );
    }
  }

  Widget _buildPlayerIndicator() {
    return Center(
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.green.shade700, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          Icons.person,
          color: Colors.green.shade700,
          size: 16,
        ),
      ),
    );
  }

  Color _getTileColor() {
    if (widget.tile == null) return Colors.grey.shade800;

    switch (widget.tile!.type) {
      case TileType.grass:
        return Colors.green.shade400;
      case TileType.water:
        return Colors.blue.shade400;
      case TileType.mountain:
        return Colors.brown.shade400;
    }
  }

  Color _getBorderColor() {
    if (widget.tile == null) return Colors.grey.shade700;

    switch (widget.tile!.type) {
      case TileType.grass:
        return Colors.green.shade600.withOpacity(0.5);
      case TileType.water:
        return Colors.blue.shade600.withOpacity(0.5);
      case TileType.mountain:
        return Colors.brown.shade600.withOpacity(0.5);
    }
  }
}
