import 'package:flutter/material.dart';

/// A widget that applies a subtle slide-up and fade-in animation to its child
/// when it first renders. The animation only happens once.
///
/// This widget is optimized for performance by:
/// 1. Using SingleTickerProviderStateMixin for efficient animation control
/// 2. Disposing the animation controller properly
/// 3. Using a memory flag to ensure animation only runs once
/// 4. Leveraging Flutter's built-in animation system
/// 5. Caching the child widget to avoid unnecessary rebuilds
/// 6. Using RepaintBoundary to isolate repaints
class AnimatedEntryWidget extends StatefulWidget {
  /// Creates an [AnimatedEntryWidget].
  ///
  /// The [child] parameter is required and represents the widget to be animated.
  /// The [duration] parameter defines how long the animation takes.
  /// The [delay] parameter adds a delay before the animation starts.
  /// The [curve] parameter defines the animation curve.
  /// The [slideOffset] parameter defines how far the widget slides up from.
  /// The [direction] parameter defines the direction of the slide animation.
  const AnimatedEntryWidget({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 600),
    this.delay = const Duration(milliseconds: 500),
    this.curve = Curves.easeOutQuart,
    this.slideOffset = 30.0,
    this.direction = SlideDirection.up,
    this.onAnimationComplete,
  });

  /// The widget to animate.
  final Widget child;

  /// The duration of the animation.
  final Duration duration;

  /// The delay before the animation starts.
  final Duration delay;

  /// The curve of the animation.
  final Curve curve;

  /// The offset from which the widget slides.
  final double slideOffset;

  /// The direction of the slide animation.
  final SlideDirection direction;

  /// Callback that is called when the animation completes.
  final VoidCallback? onAnimationComplete;

  @override
  State<AnimatedEntryWidget> createState() => _AnimatedEntryWidgetState();
}

/// The direction of the slide animation.
enum SlideDirection {
  /// Slide from bottom to top.
  up,

  /// Slide from top to bottom.
  down,

  /// Slide from left to right.
  right,

  /// Slide from right to left.
  left,
}

class _AnimatedEntryWidgetState extends State<AnimatedEntryWidget> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _slideAnimation;

  // Flag to track if animation has run
  bool _hasAnimated = false;

  @override
  void initState() {
    super.initState();

    // Initialize the animation controller with the specified duration
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    // Create fade animation that goes from 0 (transparent) to 1 (opaque)
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    );

    // Create slide animation that goes from 1 (offset position) to 0 (final position)
    _slideAnimation = CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    );

    // Add status listener to detect when animation completes
    _controller.addStatusListener(_animationStatusListener);

    // Start the animation after the specified delay
    if (mounted) {
      Future.delayed(widget.delay, () {
        if (mounted && !_hasAnimated) {
          _controller.forward();
          _hasAnimated = true;
        }
      });
    }
  }

  void _animationStatusListener(AnimationStatus status) {
    if (status == AnimationStatus.completed && widget.onAnimationComplete != null) {
      widget.onAnimationComplete!();
    }
  }

  @override
  void dispose() {
    _controller.removeStatusListener(_animationStatusListener);
    // Properly dispose the animation controller to prevent memory leaks
    _controller.dispose();
    super.dispose();
  }

  Offset _getOffsetByDirection(double value) {
    switch (widget.direction) {
      case SlideDirection.up:
        return Offset(0, widget.slideOffset * (1 - value));
      case SlideDirection.down:
        return Offset(0, -widget.slideOffset * (1 - value));
      case SlideDirection.right:
        return Offset(-widget.slideOffset * (1 - value), 0);
      case SlideDirection.left:
        return Offset(widget.slideOffset * (1 - value), 0);
    }
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _controller,
        builder: (context, child) => Opacity(
          opacity: _fadeAnimation.value.clamp(0, 1),
          child: Transform.translate(
            offset: _getOffsetByDirection(_slideAnimation.value),
            child: child,
          ),
        ),
        child: RepaintBoundary(
          key: widget.key,
          child: widget.child,
        ),
      );
}
