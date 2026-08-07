// lib/features/lock/widgets/pin_keypad.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A numeric keypad (0-9, backspace, optional action) used by the lock and
/// PIN-setup screens.
class PinKeypad extends StatelessWidget {
  const PinKeypad({
    super.key,
    required this.onDigit,
    required this.onBackspace,
    this.leadingAction,
  });

  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;

  /// Optional widget shown in the bottom-left slot (e.g. a biometric button).
  final Widget? leadingAction;

  /// Diameter of each key and the spacing between them. Kept in one place so
  /// the grid always stays perfectly aligned.
  static const double _keySize = 72;
  static const double _gap = 24;

  @override
  Widget build(BuildContext context) {
    // Three columns of keys plus two gaps between them. Constraining the whole
    // grid to this width (and centering it) keeps the columns aligned no matter
    // how wide the screen is, instead of letting `spaceEvenly` stretch them.
    const gridWidth = _keySize * 3 + _gap * 2;

    return Center(
      child: SizedBox(
        width: gridWidth,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _row(context, ['1', '2', '3']),
            const SizedBox(height: _gap),
            _row(context, ['4', '5', '6']),
            const SizedBox(height: _gap),
            _row(context, ['7', '8', '9']),
            const SizedBox(height: _gap),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _slot(child: leadingAction),
                _digitButton(context, '0'),
                _slot(
                  child: _KeypadButton(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      onBackspace();
                    },
                    child: Icon(
                      Icons.backspace_outlined,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(BuildContext context, List<String> digits) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [for (final d in digits) _digitButton(context, d)],
    );
  }

  Widget _slot({Widget? child}) {
    return SizedBox(
      width: _keySize,
      height: _keySize,
      child: child ?? const SizedBox(),
    );
  }

  Widget _digitButton(BuildContext context, String digit) {
    final colorScheme = Theme.of(context).colorScheme;
    return _slot(
      child: _KeypadButton(
        onTap: () {
          HapticFeedback.selectionClick();
          onDigit(digit);
        },
        child: Text(
          digit,
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w500,
            color: colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}

class _KeypadButton extends StatelessWidget {
  const _KeypadButton({required this.child, required this.onTap});

  final Widget child;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: PinKeypad._keySize,
          height: PinKeypad._keySize,
          child: Center(child: child),
        ),
      ),
    );
  }
}

/// The row of dots reflecting how many PIN digits have been entered.
class PinDots extends StatelessWidget {
  const PinDots({
    super.key,
    required this.length,
    required this.filled,
    this.hasError = false,
  });

  final int length;
  final int filled;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final activeColor = hasError ? colorScheme.error : colorScheme.primary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < length; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOut,
            margin: const EdgeInsets.symmetric(horizontal: 9),
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: i < filled
                  ? activeColor
                  : Colors.transparent,
              border: i < filled
                  ? null
                  : Border.all(
                      color: colorScheme.onSurface.withValues(alpha: 0.25),
                      width: 1.5,
                    ),
            ),
          ),
      ],
    );
  }
}
