import 'package:accountify/core/widgets/transitions/slide_direction.dart';
import 'package:flutter/material.dart';

/// Smooth page transitions for the app
class AppPageTransitions {
  /// Duration for all transitions
  static const Duration defaultDuration = Duration(milliseconds: 300);
  static const Duration slowDuration = Duration(milliseconds: 400);
  
  /// Standard fade + slide transition (most used)
  static Route<T> fadeSlide<T>({
    required Widget child,
    Duration duration = defaultDuration,
    SlideDirection direction = SlideDirection.right,
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => child,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      maintainState: true,
      opaque: true,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        // Slide animation
        final Offset beginOffset = slideDirectionOffset(direction);
        final tween = Tween<Offset>(
          begin: beginOffset,
          end: Offset.zero,
        ).chain(CurveTween(curve: Curves.easeOutCubic));
        
        // Fade animation
        final fadeTween = Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeOut));
        
        return FadeTransition(
          opacity: animation.drive(fadeTween),
          child: SlideTransition(
            position: animation.drive(tween),
            child: child,
          ),
        );
      },
    );
  }
  
  /// Shared axis transition (Material You style)
  static Route<T> sharedAxis<T>({
    required Widget child,
    Duration duration = defaultDuration,
    SharedAxisTransitionType type = SharedAxisTransitionType.horizontal,
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => child,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      maintainState: true,
      opaque: true,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return SharedAxisTransition(
          animation: animation,
          secondaryAnimation: secondaryAnimation,
          transitionType: type,
          child: child,
        );
      },
    );
  }
  
  /// Fade through transition (good for bottom nav switches)
  static Route<T> fadeThrough<T>({
    required Widget child,
    Duration duration = defaultDuration,
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => child,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      maintainState: true,
      opaque: true,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeThroughTransition(
          animation: animation,
          secondaryAnimation: secondaryAnimation,
          child: child,
        );
      },
    );
  }
  
  /// Scale transition (for dialogs, detail views)
  static Route<T> scale<T>({
    required Widget child,
    Duration duration = slowDuration,
    Alignment alignment = Alignment.center,
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => child,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      maintainState: true,
      opaque: true,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final scaleTween = Tween<double>(
          begin: 0.85,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeOutCubic));
        
        final fadeTween = Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeOut));
        
        return FadeTransition(
          opacity: animation.drive(fadeTween),
          child: ScaleTransition(
            scale: animation.drive(scaleTween),
            alignment: alignment,
            child: child,
          ),
        );
      },
    );
  }
  
  /// Hero-style transition with fade
  static Route<T> heroFade<T>({
    required Widget child,
    Duration duration = slowDuration,
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => child,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      maintainState: true,
      opaque: true,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final tween = Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeInOutCubic));
        
        return FadeTransition(
          opacity: animation.drive(tween),
          child: child,
        );
      },
    );
  }
}

// =============================================================================
// SHARED AXIS TRANSITION (Material You)
// =============================================================================

enum SharedAxisTransitionType { horizontal, vertical, scaled }

class SharedAxisTransition extends StatelessWidget {
  final Animation<double> animation;
  final Animation<double> secondaryAnimation;
  final SharedAxisTransitionType transitionType;
  final Widget child;

  const SharedAxisTransition({
    super.key,
    required this.animation,
    required this.secondaryAnimation,
    required this.transitionType,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Transform(
          transform: _getTransform(animation.value),
          alignment: Alignment.center,
          child: Opacity(
            opacity: _getOpacity(animation.value),
            child: child,
          ),
        );
      },
      child: child,
    );
  }

  Matrix4 _getTransform(double value) {
    switch (transitionType) {
      case SharedAxisTransitionType.horizontal:
        final slideTween = Tween<Offset>(
          begin: const Offset(30, 0),
          end: Offset.zero,
        ).chain(CurveTween(curve: Curves.easeOutCubic));
        final offset = slideTween.transform(value);
        return Matrix4.translationValues(offset.dx, offset.dy, 0);
        
      case SharedAxisTransitionType.vertical:
        final slideTween = Tween<Offset>(
          begin: const Offset(0, 30),
          end: Offset.zero,
        ).chain(CurveTween(curve: Curves.easeOutCubic));
        final offset = slideTween.transform(value);
        return Matrix4.translationValues(offset.dx, offset.dy, 0);
        
      case SharedAxisTransitionType.scaled:
        final scaleTween = Tween<double>(
          begin: 0.92,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeOutCubic));
        final scale = scaleTween.transform(value);
        return Matrix4.identity()..scale(scale, scale, 1.0);
    }
  }

  double _getOpacity(double value) {
    final fadeTween = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).chain(CurveTween(curve: Curves.easeOut));
    return fadeTween.transform(value);
  }
}

// =============================================================================
// FADE THROUGH TRANSITION (Material You)
// =============================================================================

class FadeThroughTransition extends StatelessWidget {
  final Animation<double> animation;
  final Animation<double> secondaryAnimation;
  final Widget child;

  const FadeThroughTransition({
    super.key,
    required this.animation,
    required this.secondaryAnimation,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        // Primary animation: fade in the incoming page
        final primaryFade = Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).chain(CurveTween(curve: const Interval(0.0, 0.6, curve: Curves.easeOut)));

        return Opacity(
          opacity: primaryFade.transform(animation.value),
          child: child,
        );
      },
      child: child,
    );
  }
}

// =============================================================================
// EXTENSION FOR EASIER NAVIGATION
// =============================================================================

extension NavigationExtensions on BuildContext {
  /// Push with fade slide transition
  Future<T?> pushFadeSlide<T>(
    Widget page, {
    SlideDirection direction = SlideDirection.right,
  }) {
    return Navigator.of(this).push(
      AppPageTransitions.fadeSlide(child: page, direction: direction),
    );
  }
  
  /// Push with scale transition
  Future<T?> pushScale<T>(Widget page) {
    return Navigator.of(this).push(
      AppPageTransitions.scale(child: page),
    );
  }
  
  /// Push with shared axis transition
  Future<T?> pushSharedAxis<T>(
    Widget page, {
    SharedAxisTransitionType type = SharedAxisTransitionType.horizontal,
  }) {
    return Navigator.of(this).push(
      AppPageTransitions.sharedAxis(child: page, type: type),
    );
  }
  
  /// Push with hero fade transition
  Future<T?> pushHeroFade<T>(Widget page) {
    return Navigator.of(this).push(
      AppPageTransitions.heroFade(child: page),
    );
  }
  
  /// Push replacement with fade through
  Future<T?> pushReplacementFadeThrough<T>(Widget page) {
    return Navigator.of(this).pushReplacement(
      AppPageTransitions.fadeThrough(child: page),
    );
  }
}
