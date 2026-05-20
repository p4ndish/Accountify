import 'package:flutter/material.dart';

/// Animated list builder that animates items as they appear
/// 
/// NOTE: For scrollable lists, use [SimpleListBuilder] instead to avoid
/// animation lag when scrolling fast.
class AnimatedListBuilder<T> extends StatelessWidget {
  final List<T> items;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final bool shrinkWrap;
  final ScrollPhysics? physics;
  final EdgeInsetsGeometry? padding;
  final ScrollController? scrollController;
  final Duration staggerDelay;
  final Duration itemAnimationDuration;

  const AnimatedListBuilder({
    super.key,
    required this.items,
    required this.itemBuilder,
    this.shrinkWrap = true,
    this.physics = const NeverScrollableScrollPhysics(),
    this.padding,
    this.scrollController,
    this.staggerDelay = const Duration(milliseconds: 50),
    this.itemAnimationDuration = const Duration(milliseconds: 400),
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: shrinkWrap,
      physics: physics,
      padding: padding,
      controller: scrollController,
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final delay = Duration(
          milliseconds: index * staggerDelay.inMilliseconds,
        );
        
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: itemAnimationDuration + delay,
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            // Calculate progress considering delay
            final progress = (value * (itemAnimationDuration.inMilliseconds + delay.inMilliseconds) - delay.inMilliseconds) 
                / itemAnimationDuration.inMilliseconds;
            final clampedProgress = progress.clamp(0.0, 1.0);
            
            return Opacity(
              opacity: clampedProgress,
              child: Transform.translate(
                offset: Offset(0, 15 * (1 - clampedProgress)),
                child: child,
              ),
            );
          },
          child: itemBuilder(context, item, index),
        );
      },
    );
  }
}

/// Simple list builder WITHOUT animations - use this for scrollable lists
/// where animation lag would be noticeable when scrolling fast.
class SimpleListBuilder<T> extends StatelessWidget {
  final List<T> items;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final bool shrinkWrap;
  final ScrollPhysics? physics;
  final EdgeInsetsGeometry? padding;
  final ScrollController? scrollController;

  const SimpleListBuilder({
    super.key,
    required this.items,
    required this.itemBuilder,
    this.shrinkWrap = true,
    this.physics = const NeverScrollableScrollPhysics(),
    this.padding,
    this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: shrinkWrap,
      physics: physics,
      padding: padding,
      controller: scrollController,
      itemCount: items.length,
      itemBuilder: (context, index) {
        return itemBuilder(context, items[index], index);
      },
    );
  }
}

/// Grid version of animated list builder
class AnimatedGridBuilder<T> extends StatelessWidget {
  final List<T> items;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final SliverGridDelegate gridDelegate;
  final bool shrinkWrap;
  final ScrollPhysics? physics;
  final EdgeInsetsGeometry? padding;
  final Duration staggerDelay;
  final Duration itemAnimationDuration;

  const AnimatedGridBuilder({
    super.key,
    required this.items,
    required this.itemBuilder,
    required this.gridDelegate,
    this.shrinkWrap = true,
    this.physics = const NeverScrollableScrollPhysics(),
    this.padding,
    this.staggerDelay = const Duration(milliseconds: 50),
    this.itemAnimationDuration = const Duration(milliseconds: 400),
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: shrinkWrap,
      physics: physics,
      padding: padding,
      gridDelegate: gridDelegate,
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final delay = Duration(
          milliseconds: index * staggerDelay.inMilliseconds,
        );
        
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: itemAnimationDuration + delay,
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            final progress = (value * (itemAnimationDuration.inMilliseconds + delay.inMilliseconds) - delay.inMilliseconds) 
                / itemAnimationDuration.inMilliseconds;
            final clampedProgress = progress.clamp(0.0, 1.0);
            
            return Opacity(
              opacity: clampedProgress,
              child: Transform.scale(
                scale: 0.9 + (0.1 * clampedProgress),
                child: child,
              ),
            );
          },
          child: itemBuilder(context, item, index),
        );
      },
    );
  }
}

/// Animated container that smoothly animates changes
class SmoothAnimatedContainer extends StatelessWidget {
  final Widget child;
  final Duration duration;
  final Curve curve;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BoxDecoration? decoration;
  final Alignment? alignment;
  final double? width;
  final double? height;

  const SmoothAnimatedContainer({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.easeInOutCubic,
    this.padding,
    this.margin,
    this.decoration,
    this.alignment,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: duration,
      curve: curve,
      padding: padding,
      margin: margin,
      decoration: decoration,
      alignment: alignment,
      width: width,
      height: height,
      child: child,
    );
  }
}

/// Fade through widget for switching between states
class FadeThroughSwitcher extends StatelessWidget {
  final Widget child;
  final Duration duration;

  const FadeThroughSwitcher({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 300),
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: duration,
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        final fadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: animation,
            curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
          ),
        );
        final fadeOut = Tween<double>(begin: 1.0, end: 0.0).animate(
          CurvedAnimation(
            parent: animation,
            curve: const Interval(0.4, 1.0, curve: Curves.easeIn),
          ),
        );
        
        return FadeTransition(
          opacity: animation.status == AnimationStatus.reverse 
              ? fadeOut 
              : fadeIn,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.98, end: 1.0).animate(
              CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              ),
            ),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

/// Smooth visibility widget with fade and slide
class SmoothVisibility extends StatelessWidget {
  final bool visible;
  final Widget child;
  final Duration duration;
  final Offset slideBegin;

  const SmoothVisibility({
    super.key,
    required this.visible,
    required this.child,
    this.duration = const Duration(milliseconds: 300),
    this.slideBegin = const Offset(0, 0.1),
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: visible ? 1.0 : 0.0,
      duration: duration,
      curve: Curves.easeInOut,
      child: AnimatedSlide(
        offset: visible ? Offset.zero : slideBegin,
        duration: duration,
        curve: Curves.easeOutCubic,
        child: Visibility(
          visible: visible,
          maintainState: true,
          maintainAnimation: true,
          maintainSize: true,
          child: child,
        ),
      ),
    );
  }
}

/// Hero-style container with smooth transitions
class HeroContainer extends StatelessWidget {
  final String tag;
  final Widget child;
  final VoidCallback? onTap;

  const HeroContainer({
    super.key,
    required this.tag,
    required this.child,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: tag,
      flightShuttleBuilder: (
        BuildContext flightContext,
        Animation<double> animation,
        HeroFlightDirection flightDirection,
        BuildContext fromHeroContext,
        BuildContext toHeroContext,
      ) {
        return AnimatedBuilder(
          animation: animation,
          builder: (context, child) {
            return Material(
              color: Colors.transparent,
              child: ClipRRect(
                borderRadius: BorderRadius.lerp(
                  BorderRadius.circular(12),
                  BorderRadius.circular(20),
                  animation.value,
                )!,
                child: child,
              ),
            );
          },
          child: flightDirection == HeroFlightDirection.push
              ? fromHeroContext.widget
              : toHeroContext.widget,
        );
      },
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: child,
        ),
      ),
    );
  }
}
