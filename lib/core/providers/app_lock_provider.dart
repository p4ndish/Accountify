// lib/core/providers/app_lock_provider.dart

import 'package:accountify/core/services/app_lock_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

/// Runtime state of the app lock.
enum AppLockStatus {
  /// Still reading persisted config.
  unknown,

  /// Lock is turned off; the app is always accessible.
  disabled,

  /// Lock is on and the app is currently locked (gate shown).
  locked,

  /// Lock is on and the user has authenticated for this session.
  unlocked,
}

class AppLockState {
  const AppLockState({
    this.status = AppLockStatus.unknown,
    this.biometricEnabled = false,
    this.biometricAvailable = false,
  });

  final AppLockStatus status;
  final bool biometricEnabled;
  final bool biometricAvailable;

  bool get isEnabled =>
      status == AppLockStatus.locked || status == AppLockStatus.unlocked;

  bool get isLocked => status == AppLockStatus.locked;

  AppLockState copyWith({
    AppLockStatus? status,
    bool? biometricEnabled,
    bool? biometricAvailable,
  }) {
    return AppLockState(
      status: status ?? this.status,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      biometricAvailable: biometricAvailable ?? this.biometricAvailable,
    );
  }
}

final appLockServiceProvider = Provider<AppLockService>((ref) {
  return AppLockService();
});

class AppLockNotifier extends StateNotifier<AppLockState> {
  AppLockNotifier(this._service) : super(const AppLockState()) {
    _init();
  }

  final AppLockService _service;

  Future<void> _init() async {
    final enabled = await _service.isEnabled();
    final biometricAvailable = await _service.canUseBiometrics();
    final biometricEnabled = await _service.isBiometricEnabled();
    state = state.copyWith(
      // If the lock is on, start in the locked state so the gate appears on
      // cold start; otherwise the app is always open.
      status: enabled ? AppLockStatus.locked : AppLockStatus.disabled,
      biometricEnabled: biometricEnabled && biometricAvailable,
      biometricAvailable: biometricAvailable,
    );
  }

  /// Re-read persisted config (after enabling/disabling in settings).
  Future<void> refresh() => _init();

  /// Verify a PIN and unlock on success. Returns true when unlocked.
  Future<bool> unlockWithPin(String pin) async {
    final ok = await _service.verifyPin(pin);
    if (ok) {
      state = state.copyWith(status: AppLockStatus.unlocked);
    }
    return ok;
  }

  /// Prompt biometrics and unlock on success. Returns true when unlocked.
  Future<bool> unlockWithBiometrics() async {
    if (!state.biometricEnabled) return false;
    final ok = await _service.authenticateWithBiometrics();
    if (ok) {
      state = state.copyWith(status: AppLockStatus.unlocked);
    }
    return ok;
  }

  /// Called when the app returns to the foreground: re-lock if enabled.
  void lockIfEnabled() {
    if (state.isEnabled) {
      state = state.copyWith(status: AppLockStatus.locked);
    }
  }

  /// Enable the lock with a freshly chosen PIN.
  Future<void> enableWithPin(String pin) async {
    await _service.setPin(pin);
    final biometricAvailable = await _service.canUseBiometrics();
    state = state.copyWith(
      status: AppLockStatus.unlocked,
      biometricAvailable: biometricAvailable,
    );
  }

  /// Turn the lock off entirely.
  Future<void> disable() async {
    await _service.disableLock();
    state = state.copyWith(
      status: AppLockStatus.disabled,
      biometricEnabled: false,
    );
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    await _service.setBiometricEnabled(enabled);
    final available = await _service.canUseBiometrics();
    state = state.copyWith(
      biometricEnabled: enabled && available,
      biometricAvailable: available,
    );
  }
}

final appLockProvider =
    StateNotifierProvider<AppLockNotifier, AppLockState>((ref) {
  return AppLockNotifier(ref.watch(appLockServiceProvider));
});
