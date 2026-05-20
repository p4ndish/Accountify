import 'package:accountify/core/services/background_sms_service.dart';
import 'package:accountify/core/theme/colors.dart';
import 'package:accountify/core/widgets/custom_appbar.dart';
import 'package:accountify/core/widgets/custom_cards_widget.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
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
  bool _overlayEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final smsFetchingDisabled = await _storage.read(key: _smsFetchingDisabledKey);
    final notificationsAllowed = await AwesomeNotifications().isNotificationAllowed();
    final overlayGranted = await FlutterOverlayWindow.isPermissionGranted();
    if (mounted) {
      setState(() {
        _smsFetchingDisabled = smsFetchingDisabled == 'true';
        _notificationsEnabled = notificationsAllowed;
        _overlayEnabled = overlayGranted;
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
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('App store link will be available after publishing')),
        );
      }
    }
  }

  Future<void> _requestOverlayPermission() async {
    final granted = await FlutterOverlayWindow.isPermissionGranted();
    if (!granted) {
      await FlutterOverlayWindow.requestPermission();
    }
    final newStatus = await FlutterOverlayWindow.isPermissionGranted();
    setState(() {
      _overlayEnabled = newStatus;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppbar(title: "Settings"),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 164),
          child: Column(
            // mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            spacing: 12,
            children: [
              Text(
                "Settings",
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
              ),
              CustomCardWidget(
                title: 'Personal Information',
                subTitle: 'On',
                isIconTransparent: true,
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    backgroundColor: AppColors.darkBgApp,
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
                title: 'Transaction Overlay',
                subTitle: _overlayEnabled ? 'Enabled' : 'Tap to enable',
                isIconTransparent: true,
                onTap: _requestOverlayPermission,
              ),
              CustomCardWidget(
                title: 'Rate Us',
                subTitle: 'Leave a review on the app store',
                isIconTransparent: true,
                onTap: _openAppStore,
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
    return Container(
      padding: const EdgeInsets.all(24),
      height: MediaQuery.of(context).size.height * 0.5,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Personal Information',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          const SizedBox(
            width: double.infinity,
            child: Text(
              'This app is solely running on your mobile device. No data or other information will be sent outside.\n\nThis app will only look for common bank SMS messages (127, BOA, CBE, ZemenBank) and it will work only if you give it permission. If you wish to stop SMS message fetching, you can use the toggle below.',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 16,
            children: [
              const Text(
                "Stop SMS fetching",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  // color: Color(0xFFB12828),
                ),
              ),
              Switch.adaptive(
                activeColor: AppColors.bgApp,
                activeTrackColor: Color(0xFFB12828),
                inactiveTrackColor: AppColors.darkBgSheet,
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
