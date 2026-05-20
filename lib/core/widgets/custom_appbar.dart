


import 'package:accountify/core/theme/colors.dart';
import 'package:accountify/core/theme/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CustomAppbar extends StatelessWidget implements PreferredSizeWidget {
  @override
  final Size preferredSize;
  final String title;
  const CustomAppbar({super.key, required this.title}) : preferredSize = const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
        backgroundColor: AppColors.darkBgCard,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(12.0),
            bottomRight: Radius.circular(12.0),
          ),
          // side: BorderSide(color: AppColors.primaryBrand, width: 1.0),
        ),
        title: Text(title, style: TextStyle(fontSize: 16)),
        centerTitle: true,
        actions: [
          // Theme toggle button in app bar
          Consumer(
            builder: (context, ref, _) {
              final currentTheme = ref.watch(themeProvider);
              return IconButton(
                icon: Icon(
                  currentTheme == AppThemeMode.dark
                      ? Icons.light_mode
                      : Icons.dark_mode,
                ),
                onPressed: () {
                  ref.read(themeProvider.notifier).toggleTheme();
                },
              );
            },
          ),
        ],
      );
  }
}