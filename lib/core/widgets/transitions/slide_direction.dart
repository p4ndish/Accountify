import 'package:flutter/material.dart';

/// Slide direction for page and modal transitions.
///
/// Naming convention: the direction indicates where the incoming content
/// comes FROM. For example, `SlideDirection.right` means the new content
/// slides in from the right side of the screen.
enum SlideDirection { right, left, up, down }

/// Returns the starting [Offset] for a slide-in animation from the given [direction].
Offset slideDirectionOffset(SlideDirection direction) {
  switch (direction) {
    case SlideDirection.right:
      return const Offset(1.0, 0.0);
    case SlideDirection.left:
      return const Offset(-1.0, 0.0);
    case SlideDirection.up:
      return const Offset(0.0, 1.0);
    case SlideDirection.down:
      return const Offset(0.0, -1.0);
  }
}
