// lib/features/lock/app_lock_gate.dart

import 'package:accountify/core/providers/app_lock_provider.dart';
import 'package:accountify/features/lock/screens/lock_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Wraps the app content and overlays the [LockScreen] whenever the app lock is
/// active and locked. Re-locks automatically when the app is backgrounded.
class AppLockGate extends ConsumerStatefulWidget {
  const AppLockGate({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends ConsumerState<AppLockGate>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Re-lock as soon as the app leaves the foreground so a returning user must
    // re-authenticate. Locking on "paused"/"hidden" also blanks the content
    // behind the OS app switcher on the next resume.
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      ref.read(appLockProvider.notifier).lockIfEnabled();
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(appLockProvider.select((s) => s.status));

    return Stack(
      children: [
        widget.child,
        if (status == AppLockStatus.locked)
          const Positioned.fill(child: LockScreen()),
      ],
    );
  }
}
