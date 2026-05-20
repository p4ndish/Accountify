import 'package:accountify/features/banks/screens/all_banks_screen.dart';
import 'package:accountify/core/utils/images.dart';
import 'package:accountify/home_screen.dart';
import 'package:accountify/settings_screen.dart';
import 'package:crystal_navigation_bar/crystal_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  // List of icon data for bottom navigation
  final List<IconData> iconList = [
    Icons.home_outlined,
    Icons.account_balance_wallet_outlined,
    Icons.bar_chart_outlined,
    Icons.person_outline,
  ];

  // List of active icons
  final List<IconData> activeIconList = [
    Icons.home,
    Icons.account_balance_wallet,
    Icons.bar_chart,
    Icons.person,
  ];

  // List of screens
  final List<Widget> _screens = [
    const HomeScreen(),
    const AllBanksScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        width: MediaQuery.of(context).size.width * 0.95,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: CrystalNavigationBar(

            enablePaddingAnimation: true,
            currentIndex: _currentIndex,
            // indicatorColor: Colors.white,
            unselectedItemColor: Colors.white70,
            backgroundColor: Colors.black.withOpacity(0.1),
            borderWidth: 1,
            outlineBorderColor: const Color.fromARGB(255, 128, 125, 125),
            
            onTap: (i) {
              setState(() {
                _currentIndex = i;
              });
            },
            items: [
              /// Home
              CrystalNavigationBarItem(
                icon: Icons.home,
                unselectedIcon: Icons.home_outlined,
                selectedColor: Colors.white,
                
              ),
        
              /// Favourite
              CrystalNavigationBarItem.svg(
                iconPath: AppAssets.walletIcon,
                selectedColor: Colors.red,
                
              ),
        
              // /// transactions
              // CrystalNavigationBarItem(
              //   // up down arrows
              //   icon: Icons.import_export_outlined,
              //   unselectedIcon: Icons.import_export,
              //   selectedColor: Colors.white,
              // ),
        

              /// Profile
              CrystalNavigationBarItem(
                icon: Icons.settings_outlined,
                unselectedIcon: Icons.settings,
                selectedColor: Colors.white,
              ),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildSvgIcon(String assetPath, bool isSelected) {
  return SvgPicture.asset(
    assetPath,
    width: 24,
    height: 24,
    colorFilter: ColorFilter.mode(
      isSelected ? Colors.blue : Colors.grey,
      BlendMode.srcIn,
    ),
  );
}
}

