// lib/features/lock/screens/lock_screen.dart

import 'package:accountify/core/providers/app_lock_provider.dart';
import 'package:accountify/core/utils/images.dart';
import 'package:accountify/features/lock/widgets/pin_keypad.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';

/// Full-screen gate shown while the app is locked. Accepts a PIN and, when
/// enabled, offers biometric unlock.
class LockScreen extends ConsumerStatefulWidget {
  const LockScreen({super.key});

  static const pinLength = 4;

  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen> {
  String _pin = '';
  bool _hasError = false;
  bool _verifying = false;

  @override
  void initState() {
    super.initState();
    // Offer biometrics automatically once the gate appears.
    WidgetsBinding.instance.addPostFrameCallback((_) => _tryBiometrics());
  }

  Future<void> _tryBiometrics() async {
    final state = ref.read(appLockProvider);
    if (!state.biometricEnabled) return;
    await ref.read(appLockProvider.notifier).unlockWithBiometrics();
  }

  Future<void> _onDigit(String digit) async {
    if (_verifying || _pin.length >= LockScreen.pinLength) return;
    setState(() {
      _hasError = false;
      _pin += digit;
    });
    if (_pin.length == LockScreen.pinLength) {
      await _submit();
    }
  }

  void _onBackspace() {
    if (_pin.isEmpty) return;
    setState(() {
      _hasError = false;
      _pin = _pin.substring(0, _pin.length - 1);
    });
  }

  Future<void> _submit() async {
    setState(() => _verifying = true);
    final ok = await ref.read(appLockProvider.notifier).unlockWithPin(_pin);
    if (!mounted) return;
    if (!ok) {
      HapticFeedback.heavyImpact();
      setState(() {
        _hasError = true;
        _pin = '';
        _verifying = false;
      });
    } else {
      setState(() => _verifying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final lockState = ref.watch(appLockProvider);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const Spacer(flex: 2),
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
                'Enter your PIN',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _hasError ? 'Incorrect PIN, try again' : 'Unlock Accountify',
                style: TextStyle(
                  fontSize: 13,
                  color: _hasError
                      ? colorScheme.error
                      : colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 28),
              PinDots(
                length: LockScreen.pinLength,
                filled: _pin.length,
                hasError: _hasError,
              ),
              const Spacer(flex: 3),
              PinKeypad(
                onDigit: _onDigit,
                onBackspace: _onBackspace,
                leadingAction: lockState.biometricEnabled
                    ? _BiometricButton(onTap: _tryBiometrics)
                    : null,
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

class _BiometricButton extends StatelessWidget {
  const _BiometricButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 72,
          height: 72,
          child: Icon(Icons.fingerprint, size: 30, color: colorScheme.primary),
        ),
      ),
    );
  }
}
