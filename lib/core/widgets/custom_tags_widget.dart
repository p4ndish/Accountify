import 'package:accountify/core/theme/colors.dart';
import 'package:accountify/core/utils/images.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class CustomTagWidget extends StatefulWidget {
  const CustomTagWidget({super.key, required this.title, required this.icon, required this.onTap});
  final String title;
  final String icon;
  final VoidCallback onTap;
  @override
  State<CustomTagWidget> createState() => _CustomTagWidgetState();
}

class _CustomTagWidgetState extends State<CustomTagWidget> {
  bool _isSelected = false;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() => _isSelected = !_isSelected);
        widget.onTap?.call();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), // Perfect touch target
        decoration: BoxDecoration(
          color: _isSelected
              ? const Color(0xFF06AFF8) // Selected color
              : const Color(0xFF165F7E), // Default
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min, // Important: don't stretch
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center, // This does the magic
          children: [
            // Icon inside white circle
            CircleAvatar(
              radius: 14, // Smaller = better alignment
              backgroundColor: AppColors.bgApp,
              child: SvgPicture.asset(
                widget.icon,
                // width: 16,
                // height: 16,
                
              ),
            ),
            // const SizedBox(width: 8), // Consistent spacing
            Text(
              widget.title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.white,
                height: 1, // Helps vertical centering
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CustomMonthTagWidget extends StatefulWidget {
  const CustomMonthTagWidget({super.key, required this.title,  required this.onTap});
  final String title;
  final VoidCallback onTap;
  @override
  State<CustomMonthTagWidget> createState() => _CustomMonthTagWidgetState();
}

class _CustomMonthTagWidgetState extends State<CustomMonthTagWidget> {
  bool _isSelected = false;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() => _isSelected = !_isSelected);
        widget.onTap?.call();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), // Perfect touch target
        decoration: BoxDecoration(
          color: _isSelected
              ? const Color(0xFF06AFF8) // Selected color
              : AppColors.darkBgHover, // Default
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min, // Important: don't stretch
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center, // This does the magic
          children: [
            
            // const SizedBox(width: 8), // Consistent spacing
            Text(
              widget.title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.white,
                height: 1, // Helps vertical centering
              ),
            ),
          ],
        ),
      ),
    );
  }
}
