import 'package:accountify/core/theme/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class CustomStatCardWidget extends StatelessWidget {
  final String text;
  final String amount;
  final String iconPath;
  final bool isReceived;

  const CustomStatCardWidget({
    super.key,
    required this.text,
    required this.amount,
    required this.iconPath,
    required this.isReceived,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      // width: MediaQuery.of(context).size.width * 0.3,
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppColors.darkBgHover,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: isReceived
                    ? const Color.fromARGB(103, 22, 163, 74)
                    : const Color.fromARGB(255, 186, 48, 48),
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: SvgPicture.asset(
                    iconPath,
                    width: 16,
                    height: 16,
                    colorFilter: ColorFilter.mode(
                      isReceived
                          ? AppColors.bgReceived
                          : AppColors.darkTextPrimary,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                text,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isReceived
                      ? AppColors.darkTextReceived
                      : AppColors.darkTextSent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              "$amount Br.",
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isReceived
                    ? AppColors.textReceivedOpacity
                    : AppColors.textSentOpacity,
              ),
            ),
          ),
        ],
      ),
    );
  }
}