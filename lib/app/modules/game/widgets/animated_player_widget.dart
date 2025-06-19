// lib/app/modules/game/widgets/animated_player_widget.dart
import 'package:flutter/material.dart';
import '../../../data/models/position_model.dart';

class AnimatedPlayerWidget extends StatefulWidget {
  final Position currentPosition;
  final Position? previousPosition;
  final double tileSize;
  final Widget child;
  final Duration animationDuration;
  final VoidCallback? onAnimationComplete;

  const AnimatedPlayerWidget({
    super.key,
    required this.currentPosition,
    this.previousPosition,
    required this.tileSize,
    required this.child,
    this.animationDuration = const Duration(milliseconds: 300),
    this.onAnimationComplete,
  });

  @override
  State<AnimatedPlayerWidget> createState() => _AnimatedPlayerWidgetState();
}

class _AnimatedPlayerWidgetState extends State<AnimatedPlayerWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    _setupAnimations();

    if (widget.previousPosition != null &&
        widget.previousPosition != widget.currentPosition) {
      _controller.forward().then((_) {
        widget.onAnimationComplete?.call();
      });
    }
  }

  void _setupAnimations() {
    // Animation de déplacement
    final begin = widget.previousPosition != null
        ? Offset(
            (widget.previousPosition!.x - widget.currentPosition.x).toDouble(),
            (widget.previousPosition!.y - widget.currentPosition.y).toDouble(),
          )
        : Offset.zero;

    _offsetAnimation = Tween<Offset>(
      begin: begin,
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    ));

    // Animation d'échelle pour effet de saut
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.15)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.15, end: 1.0)
            .chain(CurveTween(curve: Curves.bounceOut)),
        weight: 70,
      ),
    ]).animate(_controller);

    // Animation de rebond vertical
    _bounceAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0, end: -10)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: -10, end: 0)
            .chain(CurveTween(curve: Curves.bounceOut)),
        weight: 70,
      ),
    ]).animate(_controller);
  }

  @override
  void didUpdateWidget(AnimatedPlayerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.currentPosition != widget.currentPosition) {
      _controller.reset();
      _setupAnimations();
      _controller.forward().then((_) {
        widget.onAnimationComplete?.call();
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
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(
            _offsetAnimation.value.dx * widget.tileSize,
            _offsetAnimation.value.dy * widget.tileSize +
                _bounceAnimation.value,
          ),
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: widget.child,
          ),
        );
      },
    );
  }
}
