import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/colors.dart';
import '../../../theme/spacing.dart';

class AnimatedLikeButton extends StatefulWidget {
  final bool isLiked;
  final int likesCount;
  final Future<bool> Function() onToggleLike;

  const AnimatedLikeButton({
    super.key,
    required this.isLiked,
    required this.likesCount,
    required this.onToggleLike,
  });

  @override
  State<AnimatedLikeButton> createState() => _AnimatedLikeButtonState();
}

class _AnimatedLikeButtonState extends State<AnimatedLikeButton>
    with TickerProviderStateMixin {
  late AnimationController _bounceController;
  late Animation<double> _bounceAnimation;

  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();

    // Micro-scale bounce animation for click
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _bounceAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.3), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.3, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(
      parent: _bounceController,
      curve: Curves.easeOutCubic,
    ));

    // Shake animation on error rollback
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _shakeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _bounceController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  Future<void> _handleTap() async {
    _bounceController.forward(from: 0.0);

    final success = await widget.onToggleLike();
    if (!success && mounted) {
      // Trigger error shake animation
      _shakeController.forward(from: 0.0);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to update like. Please check your connection.',
            style: GoogleFonts.ibmPlexSans(color: Colors.white),
          ),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shakeAnimation,
      builder: (context, child) {
        // Compute horizontal offset for shake
        final offset = sin(_shakeAnimation.value * pi * 4) * 6;
        return Transform.translate(
          offset: Offset(offset, 0),
          child: child,
        );
      },
      child: InkWell(
        onTap: _handleTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ScaleTransition(
                scale: _bounceAnimation,
                child: Icon(
                  widget.isLiked
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  size: 20,
                  color: widget.isLiked
                      ? AppColors.secondary
                      : AppColors.textSecondary,
                ),
              ),
              AppSpacing.gapH6,
              Text(
                '${widget.likesCount}',
                style: GoogleFonts.ibmPlexSans(
                  fontSize: 13,
                  fontWeight: widget.isLiked ? FontWeight.w700 : FontWeight.w500,
                  color: widget.isLiked
                      ? AppColors.primary
                      : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
