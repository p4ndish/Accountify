import 'package:accountify/core/widgets/transitions/slide_direction.dart';
import 'package:flutter/material.dart';

/// Smooth modal transitions for bottom sheets and dialogs
class ModalTransitions {
  /// Duration for all modal transitions
  static const Duration defaultDuration = Duration(milliseconds: 350);
  static const Duration fastDuration = Duration(milliseconds: 250);
  
  /// Show smooth bottom sheet with slide + fade animation
  static Future<T?> showSmoothBottomSheet<T>({
    required BuildContext context,
    required Widget child,
    bool isScrollControlled = true,
    bool useSafeArea = true,
    Color? backgroundColor,
    double? elevation,
    ShapeBorder? shape,
    Clip? clipBehavior,
    BoxConstraints? constraints,
    bool enableDrag = true,
    bool isDismissible = true,
    RouteSettings? routeSettings,
    AnimationController? transitionAnimationController,
    double initialChildSize = 0.5,
    double minChildSize = 0.25,
    double maxChildSize = 0.95,
    bool expand = false,
    bool snap = false,
    List<double>? snapSizes,
    DraggableScrollableController? controller,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      useSafeArea: useSafeArea,
      backgroundColor: backgroundColor ?? Colors.transparent,
      elevation: elevation ?? 0,
      shape: shape,
      clipBehavior: clipBehavior,
      constraints: constraints,
      enableDrag: enableDrag,
      isDismissible: isDismissible,
      routeSettings: routeSettings,
      transitionAnimationController: transitionAnimationController,
      builder: (context) => _AnimatedBottomSheet(
        child: isScrollControlled
            ? DraggableScrollableSheet(
                initialChildSize: initialChildSize,
                minChildSize: minChildSize,
                maxChildSize: maxChildSize,
                expand: expand,
                snap: snap,
                snapSizes: snapSizes,
                controller: controller,
                builder: (context, scrollController) {
                  return _BottomSheetContent(
                    scrollController: scrollController,
                    child: child,
                  );
                },
              )
            : child,
      ),
    );
  }
  
  /// Show smooth modal bottom sheet with custom animation
  static Future<T?> showCustomModalBottomSheet<T>({
    required BuildContext context,
    required WidgetBuilder builder,
    bool isScrollControlled = false,
    bool useSafeArea = false,
    Color? backgroundColor,
    double? elevation,
    ShapeBorder? shape,
    Clip? clipBehavior,
    BoxConstraints? constraints,
    bool enableDrag = true,
    bool isDismissible = true,
    RouteSettings? routeSettings,
    Duration duration = defaultDuration,
  }) {
    return Navigator.of(context).push(
      _ModalBottomSheetRoute<T>(
        builder: builder,
        isScrollControlled: isScrollControlled,
        useSafeArea: useSafeArea,
        barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
        backgroundColor: backgroundColor,
        elevation: elevation,
        shape: shape,
        clipBehavior: clipBehavior,
        constraints: constraints,
        isDismissible: isDismissible,
        enableDrag: enableDrag,
        settings: routeSettings,
        transitionDuration: duration,
      ),
    );
  }
  
  /// Show smooth dialog with scale + fade animation
  static Future<T?> showSmoothDialog<T>({
    required BuildContext context,
    required Widget child,
    bool barrierDismissible = true,
    Color? barrierColor,
    String? barrierLabel,
    bool useSafeArea = true,
    bool useRootNavigator = true,
    RouteSettings? routeSettings,
    Offset? anchorPoint,
    Duration duration = fastDuration,
  }) {
    return showGeneralDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierLabel: barrierLabel ?? MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: barrierColor ?? Colors.black54,
      useRootNavigator: useRootNavigator,
      routeSettings: routeSettings,
      anchorPoint: anchorPoint,
      pageBuilder: (context, animation, secondaryAnimation) {
        return child;
      },
      transitionDuration: duration,
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final scaleTween = Tween<double>(
          begin: 0.8,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeOutCubic));
        
        final fadeTween = Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeOut));
        
        final slideTween = Tween<Offset>(
          begin: const Offset(0, 0.1),
          end: Offset.zero,
        ).chain(CurveTween(curve: Curves.easeOutCubic));
        
        return FadeTransition(
          opacity: animation.drive(fadeTween),
          child: ScaleTransition(
            scale: animation.drive(scaleTween),
            child: SlideTransition(
              position: animation.drive(slideTween),
              child: child,
            ),
          ),
        );
      },
    );
  }
  
  /// Show smooth fullscreen modal with slide transition
  static Future<T?> showFullscreenModal<T>({
    required BuildContext context,
    required Widget child,
    SlideDirection direction = SlideDirection.up,
    bool barrierDismissible = true,
    Color? barrierColor,
    Duration duration = defaultDuration,
  }) {
    return Navigator.of(context).push(
      PageRouteBuilder<T>(
        opaque: false,
        barrierDismissible: barrierDismissible,
        barrierColor: barrierColor ?? Colors.black54,
        transitionDuration: duration,
        reverseTransitionDuration: duration,
        pageBuilder: (context, animation, secondaryAnimation) {
          return GestureDetector(
            onTap: barrierDismissible ? () => Navigator.of(context).pop() : null,
            child: Container(
              color: Colors.transparent,
              child: GestureDetector(
                onTap: () {}, // Prevent tap through
                child: child,
              ),
            ),
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final Offset beginOffset = slideDirectionOffset(direction);
          
          final slideTween = Tween<Offset>(
            begin: beginOffset,
            end: Offset.zero,
          ).chain(CurveTween(curve: Curves.easeOutCubic));
          
          final fadeTween = Tween<double>(
            begin: 0.0,
            end: 1.0,
          ).chain(CurveTween(curve: Curves.easeOut));
          
          return FadeTransition(
            opacity: animation.drive(fadeTween),
            child: SlideTransition(
              position: animation.drive(slideTween),
              child: child,
            ),
          );
        },
      ),
    );
  }
}

// =============================================================================
// ANIMATED BOTTOM SHEET CONTENT
// =============================================================================

class _AnimatedBottomSheet extends StatelessWidget {
  final Widget child;

  const _AnimatedBottomSheet({required this.child});

  @override
  Widget build(BuildContext context) {
    // showModalBottomSheet already provides slide-up + fade animation.
    // No additional animation wrapper needed.
    return child;
  }
}

class _BottomSheetContent extends StatelessWidget {
  final ScrollController? scrollController;
  final Widget child;

  const _BottomSheetContent({
    this.scrollController,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 48,
            height: 5,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2.5),
            ),
          ),
          // Content
          Flexible(
            child: PrimaryScrollController(
              controller: scrollController ?? PrimaryScrollController.of(context),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// CUSTOM MODAL BOTTOM SHEET ROUTE
// =============================================================================

class _ModalBottomSheetRoute<T> extends PopupRoute<T> {
  final WidgetBuilder builder;
  final bool isScrollControlled;
  final bool useSafeArea;
  @override
  final String? barrierLabel;
  final Color? backgroundColor;
  final double? elevation;
  final ShapeBorder? shape;
  final Clip? clipBehavior;
  final BoxConstraints? constraints;
  final bool isDismissible;
  final bool enableDrag;
  @override
  final Duration transitionDuration;

  _ModalBottomSheetRoute({
    required this.builder,
    required this.isScrollControlled,
    required this.useSafeArea,
    this.barrierLabel,
    this.backgroundColor,
    this.elevation,
    this.shape,
    this.clipBehavior,
    this.constraints,
    required this.isDismissible,
    required this.enableDrag,
    super.settings,
    required this.transitionDuration,
  });

  @override
  Color? get barrierColor => Colors.black54;

  @override
  bool get barrierDismissible => isDismissible;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    final theme = Theme.of(context);
    
    Widget content = builder(context);

    final dragHandle = Container(
      margin: const EdgeInsets.only(top: 12, bottom: 8),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(2),
      ),
    );

    if (isScrollControlled) {
      content = DraggableScrollableSheet(
        expand: false,
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: backgroundColor ?? theme.colorScheme.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.shadow.withValues(alpha: 0.2),
                  blurRadius: 20,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: ListView(
              controller: scrollController,
              padding: EdgeInsets.zero,
              children: [
                dragHandle,
                content,
              ],
            ),
          );
        },
      );
    } else {
      content = Container(
        decoration: BoxDecoration(
          color: backgroundColor ?? theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.shadow.withValues(alpha: 0.2),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            dragHandle,
            content,
          ],
        ),
      );
    }
    
    if (useSafeArea) {
      content = SafeArea(child: content);
    }
    
    return content;
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final slideTween = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).chain(CurveTween(curve: Curves.easeOutCubic));
    
    final fadeTween = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).chain(CurveTween(curve: Curves.easeOut));
    
    return FadeTransition(
      opacity: animation.drive(fadeTween),
      child: SlideTransition(
        position: animation.drive(slideTween),
        child: child,
      ),
    );
  }
}

// =============================================================================
// EXTENSION FOR EASIER MODAL ACCESS
// =============================================================================

extension ModalExtensions on BuildContext {
  Future<T?> showSmoothBottomSheet<T>({
    required Widget child,
    bool isScrollControlled = true,
    double initialChildSize = 0.5,
    double minChildSize = 0.25,
    double maxChildSize = 0.95,
    bool snap = false,
    List<double>? snapSizes,
  }) {
    return ModalTransitions.showSmoothBottomSheet<T>(
      context: this,
      child: child,
      isScrollControlled: isScrollControlled,
      initialChildSize: initialChildSize,
      minChildSize: minChildSize,
      maxChildSize: maxChildSize,
      snap: snap,
      snapSizes: snapSizes,
    );
  }
  
  Future<T?> showSmoothDialog<T>({
    required Widget child,
    bool barrierDismissible = true,
  }) {
    return ModalTransitions.showSmoothDialog<T>(
      context: this,
      child: child,
      barrierDismissible: barrierDismissible,
    );
  }
  
  Future<T?> showFullscreenModal<T>({
    required Widget child,
    SlideDirection direction = SlideDirection.up,
  }) {
    return ModalTransitions.showFullscreenModal<T>(
      context: this,
      child: child,
      direction: direction,
    );
  }
}
