import 'package:accountify/core/providers/app_lock_provider.dart';
import 'package:accountify/core/providers/database_provider.dart';
import 'package:accountify/core/providers/message_provider.dart';
import 'package:accountify/core/services/background_sms_service.dart';
import 'package:accountify/core/widgets/custom_appbar.dart';
import 'package:accountify/core/widgets/custom_cards_widget.dart';
import 'package:accountify/features/lock/screens/pin_setup_screen.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

const _smsFetchingDisabledKey = 'sms_fetching_disabled';
const FlutterSecureStorage _storage = FlutterSecureStorage();

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _smsFetchingDisabled = false;
  bool _notificationsEnabled = false;
  bool _isReimporting = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final smsFetchingDisabled = await _storage.read(key: _smsFetchingDisabledKey);
    final notificationsAllowed = await AwesomeNotifications().isNotificationAllowed();
    if (mounted) {
      setState(() {
        _smsFetchingDisabled = smsFetchingDisabled == 'true';
        _notificationsEnabled = notificationsAllowed;
      });
    }
  }

  Future<void> _toggleSmsFetching(bool disabled) async {
    await _storage.write(key: _smsFetchingDisabledKey, value: disabled ? 'true' : 'false');
    if (disabled) {
      BackgroundSmsService().stopListening();
    } else {
      await BackgroundSmsService().startListening();
    }
    setState(() {
      _smsFetchingDisabled = disabled;
    });
  }

  Future<void> _openNotificationSettings() async {
    final isAllowed = await AwesomeNotifications().isNotificationAllowed();
    if (!isAllowed) {
      await AwesomeNotifications().requestPermissionToSendNotifications();
    }
    final newStatus = await AwesomeNotifications().isNotificationAllowed();
    setState(() {
      _notificationsEnabled = newStatus;
    });
  }

  Future<void> _openAppStore() async {
    // Replace with your actual app store URL when published
    const playStoreUrl = 'https://play.google.com/store/apps/details?id=com.accountify.app';
    final uri = Uri.parse(playStoreUrl);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('App store link will be available after publishing')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open the app store. Please try again later.')),
        );
      }
    }
  }

  Future<void> _reimportTransactions() async {
    if (_isReimporting) return;
    setState(() => _isReimporting = true);

    try {
      final notifier = ref.read(smsImportNotifierProvider.notifier);
      final imported = await notifier.refreshMessages();

      // Refresh all balance/transaction views so the corrected data shows up.
      ref.invalidate(banksListProvider);
      ref.invalidate(transactionsListProvider);
      ref.invalidate(transactionsWithBanksListProvider);
      ref.invalidate(overallBalanceProvider);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            imported > 0
                ? 'Re-import complete. $imported new transaction(s) added.'
                : 'Re-import complete. Everything is up to date.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Re-import failed. Please check SMS permission and try again.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _isReimporting = false);
    }
  }

  void _openAppLockSheet() {
    final colorScheme = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      backgroundColor: colorScheme.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const _AppLockBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: CustomAppbar(title: "Settings"),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 120),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            spacing: 12,
            children: [
              CustomCardWidget(
                title: 'Privacy Settings',
                subTitle: _smsFetchingDisabled ? 'Disabled' : 'Enabled',
                isIconTransparent: true,
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    backgroundColor: colorScheme.surface,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                    ),
                    isScrollControlled: true,
                    builder: (context) => _PersonalInfoBottomSheet(
                      initialValue: _smsFetchingDisabled,
                      onChanged: _toggleSmsFetching,
                    ),
                  );
                },
              ),
              CustomCardWidget(
                title: 'Notifications',
                subTitle: _notificationsEnabled ? 'Enabled' : 'Disabled',
                isIconTransparent: true,
                onTap: _openNotificationSettings,
              ),
              CustomCardWidget(
                title: 'App Lock',
                subTitle: ref.watch(appLockProvider).isEnabled
                    ? 'Enabled'
                    : 'Disabled',
                isIconTransparent: true,
                onTap: _openAppLockSheet,
              ),
              CustomCardWidget(
                title: 'Re-import transactions',
                subTitle: _isReimporting
                    ? 'Re-importing...'
                    : 'Re-scan SMS to fix balances',
                isIconTransparent: true,
                onTap: _isReimporting ? () {} : _reimportTransactions,
              ),
              CustomCardWidget(
                title: 'Rate Us',
                subTitle: 'Leave a review on the app store',
                isIconTransparent: true,
                onTap: _openAppStore,
              ),
              CustomCardWidget(
                title: 'Share App',
                subTitle: 'Tell others about Accountify',
                isIconTransparent: true,
                onTap: () {
                  Share.share(
                    'Check out Accountify - track your Ethiopian bank transactions! https://play.google.com/store/apps/details?id=com.accountify.app',
                  );
                },
              ),
              const SizedBox(height: 24),
              Text(
                'Version 1.0.0',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PersonalInfoBottomSheet extends StatefulWidget {
  final bool initialValue;
  final ValueChanged<bool> onChanged;

  const _PersonalInfoBottomSheet({
    required this.initialValue,
    required this.onChanged,
  });

  @override
  _PersonalInfoBottomSheetState createState() => _PersonalInfoBottomSheetState();
}

class _PersonalInfoBottomSheetState extends State<_PersonalInfoBottomSheet> {
  late bool _isEnabled;

  @override
  void initState() {
    super.initState();
    _isEnabled = widget.initialValue;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(24),
      height: MediaQuery.of(context).size.height * 0.5,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Privacy Settings',
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: Text(
              'This app is solely running on your mobile device. No data or other information will be sent outside.\n\nThis app will only look for common bank SMS messages (127, BOA, CBE, ZemenBank) and it will work only if you give it permission. If you wish to stop SMS message fetching, you can use the toggle below.',
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 16,
            children: [
              Text(
                "Stop SMS fetching",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Switch.adaptive(
                activeColor: colorScheme.primary,
                activeTrackColor: colorScheme.error,
                inactiveTrackColor: colorScheme.onSurface.withValues(alpha: 0.2),
                value: _isEnabled,
                onChanged: (bool value) {
                  setState(() {
                    _isEnabled = value;
                  });
                  widget.onChanged(value);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AppLockBottomSheet extends ConsumerStatefulWidget {
  const _AppLockBottomSheet();

  @override
  ConsumerState<_AppLockBottomSheet> createState() =>
      _AppLockBottomSheetState();
}

class _AppLockBottomSheetState extends ConsumerState<_AppLockBottomSheet> {
  bool _busy = false;

  Future<String?> _promptNewPin() {
    return Navigator.of(context).push<String>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => const PinSetupScreen(),
      ),
    );
  }

  Future<void> _enable() async {
    final pin = await _promptNewPin();
    if (pin == null || !mounted) return;
    setState(() => _busy = true);
    await ref.read(appLockProvider.notifier).enableWithPin(pin);
    if (!mounted) return;
    setState(() => _busy = false);
    _toast('App lock enabled');
  }

  Future<void> _changePin() async {
    final pin = await _promptNewPin();
    if (pin == null || !mounted) return;
    setState(() => _busy = true);
    await ref.read(appLockProvider.notifier).enableWithPin(pin);
    if (!mounted) return;
    setState(() => _busy = false);
    _toast('PIN updated');
  }

  Future<void> _disable() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Turn off app lock?'),
        content: const Text(
          'Anyone with access to this device will be able to open the app.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Turn off'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _busy = true);
    await ref.read(appLockProvider.notifier).disable();
    if (!mounted) return;
    setState(() => _busy = false);
    _toast('App lock disabled');
  }

  Future<void> _toggleBiometric(bool value) async {
    setState(() => _busy = true);
    await ref.read(appLockProvider.notifier).setBiometricEnabled(value);
    if (!mounted) return;
    setState(() => _busy = false);
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final lock = ref.watch(appLockProvider);
    final isEnabled = lock.isEnabled;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'App Lock',
              style: TextStyle(
                color: colorScheme.onSurface,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isEnabled
                  ? 'Accountify asks for your PIN when opened or brought back to the foreground.'
                  : 'Protect your transactions with a PIN. You can also unlock with biometrics if your device supports it.',
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 20),
            if (!isEnabled)
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _busy ? null : _enable,
                  icon: const Icon(Icons.lock_outline),
                  label: const Text('Enable app lock'),
                ),
              )
            else ...[
              if (lock.biometricAvailable)
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Unlock with biometrics'),
                  subtitle: const Text('Fingerprint or face'),
                  value: lock.biometricEnabled,
                  onChanged: _busy ? null : _toggleBiometric,
                ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.password_rounded),
                title: const Text('Change PIN'),
                onTap: _busy ? null : _changePin,
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.lock_open_rounded, color: colorScheme.error),
                title: Text(
                  'Turn off app lock',
                  style: TextStyle(color: colorScheme.error),
                ),
                onTap: _busy ? null : _disable,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
