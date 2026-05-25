import 'package:accountify/core/services/background_sms_service.dart';
import 'package:accountify/core/widgets/custom_appbar.dart';
import 'package:accountify/core/widgets/custom_cards_widget.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

const _smsFetchingDisabledKey = 'sms_fetching_disabled';
const FlutterSecureStorage _storage = FlutterSecureStorage();

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _smsFetchingDisabled = false;
  bool _notificationsEnabled = false;

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
