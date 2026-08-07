// lib/features/lock/screens/pin_setup_screen.dart

import 'package:accountify/core/utils/images.dart';
import 'package:accountify/features/lock/screens/lock_screen.dart';
import 'package:accountify/features/lock/widgets/pin_keypad.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';

/// Two-step PIN setup: enter a new PIN, then confirm it. Pops with the chosen
/// PIN (a [String]) on success, or `null` if cancelled.
class PinSetupScreen extends StatefulWidget {
  const PinSetupScreen({super.key});

  @override
  State<PinSetupScreen> createState() => _PinSetupScreenState();
}

enum _SetupStage { enter, confirm }

class _PinSetupScreenState extends State<PinSetupScreen> {
  _SetupStage _stage = _SetupStage.enter;
  String _firstPin = '';
  String _pin = '';
  bool _hasError = false;

  int get _pinLength => LockScreen.pinLength;

  void _onDigit(String digit) {
    if (_pin.length >= _pinLength) return;
    setState(() {
      _hasError = false;
      _pin += digit;
    });
    if (_pin.length == _pinLength) {
      _handleComplete();
    }
  }

  void _onBackspace() {
    if (_pin.isEmpty) return;
    setState(() {
      _hasError = false;
      _pin = _pin.substring(0, _pin.length - 1);
    });
  }

  void _handleComplete() {
    if (_stage == _SetupStage.enter) {
      setState(() {
        _firstPin = _pin;
        _pin = '';
        _stage = _SetupStage.confirm;
      });
      return;
    }

    // Confirm stage.
    if (_pin == _firstPin) {
      Navigator.of(context).pop(_pin);
    } else {
      HapticFeedback.heavyImpact();
      setState(() {
        _hasError = true;
        _pin = '';
        _firstPin = '';
        _stage = _SetupStage.enter;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isConfirm = _stage == _SetupStage.confirm;

    final title = isConfirm ? 'Confirm your PIN' : 'Create a PIN';
    final subtitle = _hasError
        ? "PINs didn't match, start over"
        : (isConfirm
              ? 'Re-enter the same PIN'
              : 'This locks Accountify on this device');

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const Spacer(),
              SvgPicture.asset(
                AppAssets.appLogo,
                width: 72,
                height: 72,
                colorFilter: ColorFilter.mode(
                  colorScheme.onSurface,
                  BlendMode.srcIn,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                title,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: _hasError
                      ? colorScheme.error
                      : colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 28),
              PinDots(
                length: _pinLength,
                filled: _pin.length,
                hasError: _hasError,
              ),
              const Spacer(flex: 2),
              PinKeypad(onDigit: _onDigit, onBackspace: _onBackspace),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
