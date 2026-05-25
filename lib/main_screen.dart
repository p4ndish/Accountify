import 'package:accountify/core/utils/images.dart';
import 'package:accountify/features/banks/screens/all_banks_screen.dart';
import 'package:accountify/home_screen.dart';
import 'package:accountify/settings_screen.dart';
import 'package:crystal_navigation_bar/crystal_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  bool _isNavBarVisible = true;
  double _lastScrollOffset = 0;

  // List of icon data for bottom navigation
  final List<IconData> iconList = [
    Icons.home_outlined,
    Icons.account_balance_wallet_outlined,
    Icons.bar_chart_outlined,
  ];

  // List of active icons
  final List<IconData> activeIconList = [
    Icons.home,
    Icons.account_balance_wallet,
    Icons.bar_chart,
  ];

  // List of screens
  final List<Widget> _screens = [
    const HomeScreen(),
    const AllBanksScreen(),
    const SettingsScreen(),
  ];

  bool _handleScrollNotification(ScrollNotification notification) {
    if (notification is ScrollUpdateNotification) {
      final currentOffset = notification.metrics.pixels;
      final delta = currentOffset - _lastScrollOffset;

      if (delta > 10 && currentOffset > 50 && _isNavBarVisible) {
        setState(() => _isNavBarVisible = false);
      } else if (delta < -10 || currentOffset <= 0) {
        if (!_isNavBarVisible) setState(() => _isNavBarVisible = true);
      }

      _lastScrollOffset = currentOffset;
    } else if (notification is ScrollEndNotification) {
      if (notification.metrics.pixels <= 0) {
        if (!_isNavBarVisible) setState(() => _isNavBarVisible = true);
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        // If not on home tab, go back to home; otherwise exit app
        if (_currentIndex != 0) {
          setState(() {
            _currentIndex = 0;
            _isNavBarVisible = true;
            _lastScrollOffset = 0;
          });
        } else {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
      extendBody: true,
      body: NotificationListener<ScrollNotification>(
        onNotification: _handleScrollNotification,
        child: _screens[_currentIndex],
      ),
      bottomNavigationBar: AnimatedSlide(
        offset: _isNavBarVisible ? Offset.zero : const Offset(0, 1),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        child: AnimatedOpacity(
          opacity: _isNavBarVisible ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.95,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: CrystalNavigationBar(
                enablePaddingAnimation: true,
                currentIndex: _currentIndex,
                unselectedItemColor: colorScheme.onSurface.withValues(alpha: 0.5),
                backgroundColor: colorScheme.surface.withValues(alpha: 0.1),
                borderWidth: 1,
                outlineBorderColor: colorScheme.outline,
                onTap: (i) {
                  setState(() {
                    _currentIndex = i;
                    _isNavBarVisible = true;
                    _lastScrollOffset = 0;
                  });
                },
                items: [
                  CrystalNavigationBarItem(
                    icon: Icons.home,
                    unselectedIcon: Icons.home_outlined,
                    selectedColor: Colors.white,
                  ),
                  CrystalNavigationBarItem.svg(
                    iconPath: AppAssets.walletIcon,
                    selectedColor: Colors.white,
                  ),
                  CrystalNavigationBarItem(
                    icon: Icons.settings_outlined,
                    unselectedIcon: Icons.settings,
                    selectedColor: Colors.white,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      ),
    );
  }
}
