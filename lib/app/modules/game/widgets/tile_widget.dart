// lib/app/modules/game/widgets/tile_widget.dart
import 'package:flutter/material.dart';
import '../../../data/models/tile_model.dart';
import '../../../data/models/position_model.dart';

class TileWidget extends StatefulWidget {
  final Tile? tile;
  final Position position;
  final bool isRevealed;
  final bool isPlayerPosition;
  final bool hasOtherPlayer;
  final bool existsInDatabase;
  final bool shouldAnimate;
  final int animationDelay;

  const TileWidget({
    super.key,
    this.tile,
    required this.position,
    required this.isRevealed,
    required this.isPlayerPosition,
    required this.hasOtherPlayer,
    this.existsInDatabase = false,
    this.shouldAnimate = false,
    this.animationDelay = 0,
  });

  @override
  State<TileWidget> createState() => _TileWidgetState();
}

class _TileWidgetState extends State<TileWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _flipAnimation;
  late Animation<double> _scaleAnimation;
  bool _hasAnimated = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _flipAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.85),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.85, end: 1.1),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.1, end: 1.0),
        weight: 25,
      ),
    ]).animate(_controller);

    // Démarrer l'animation si nécessaire
    if (widget.shouldAnimate && !_hasAnimated) {
      Future.delayed(Duration(milliseconds: widget.animationDelay), () {
        if (mounted) {
          _controller.forward();
          _hasAnimated = true;
        }
      });
    }
  }

  @override
  void didUpdateWidget(TileWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Si on doit animer et qu'on ne l'a pas encore fait
    if (widget.shouldAnimate && !_hasAnimated && !_controller.isAnimating) {
      Future.delayed(Duration(milliseconds: widget.animationDelay), () {
        if (mounted) {
          _controller.forward();
          _hasAnimated = true;
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Si on doit animer ou si l'animation est en cours
    if (widget.shouldAnimate || _controller.isAnimating || _hasAnimated) {
      return AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final isShowingBack = _flipAnimation.value < 0.5;
          final rotationAngle = _flipAnimation.value * 3.14159;

          Widget content;
          if (isShowingBack) {
            content = _buildHiddenCard();
          } else {
            content = Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()..rotateY(3.14159),
              child: _buildRevealedCard(),
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

    // Sinon, afficher normalement
    return widget.isRevealed ? _buildRevealedCard() : _buildHiddenCard();
  }

  Widget _buildHiddenCard() {
    return Container(
      margin: const EdgeInsets.all(1),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: widget.existsInDatabase
              ? [
                  Colors.grey.shade700,
                  Colors.grey.shade600,
                  Colors.grey.shade700
                ]
              : [Colors.grey.shade900, Colors.black87, Colors.grey.shade900],
        ),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: widget.existsInDatabase
              ? Colors.grey.shade500
              : Colors.grey.shade800,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Center(
        child: Icon(
          widget.existsInDatabase ? Icons.help_outline : Icons.explore,
          color: widget.existsInDatabase
              ? Colors.grey.shade600
              : Colors.grey.shade800,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildRevealedCard() {
    if (widget.tile == null) return _buildHiddenCard();

    return Container(
      margin: const EdgeInsets.all(1),
      decoration: BoxDecoration(
        color: _getTileColor(),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: _getBorderColor(),
          width: widget.isPlayerPosition ? 2.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (widget.tile != null) _buildTexturePattern(),
          if (widget.hasOtherPlayer) _buildOtherPlayerIndicator(),
        ],
      ),
    );
  }

  Widget _buildTexturePattern() {
    // Simple patterns pour chaque type
    switch (widget.tile!.type) {
      case TileType.grass:
        return Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.topLeft,
              radius: 1.5,
              colors: [
                Colors.green.shade300.withOpacity(0.3),
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

  Widget _buildOtherPlayerIndicator() {
    return Center(
      child: Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: const Icon(Icons.person, color: Colors.white, size: 16),
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
    if (widget.isPlayerPosition) return Colors.yellow;
    if (widget.tile == null) return Colors.black26;
    switch (widget.tile!.type) {
      case TileType.grass:
        return Colors.green.shade600.withOpacity(0.3);
      case TileType.water:
        return Colors.blue.shade600.withOpacity(0.3);
      case TileType.mountain:
        return Colors.brown.shade600.withOpacity(0.3);
    }
  }
}
