import 'package:accountify/core/theme/colors.dart';
import 'package:accountify/core/utils/images.dart';
import 'package:accountify/core/widgets/statCard_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class CustomHeaderWidget extends StatefulWidget {
  final String title;
  final String? iconPath;
  final List<Color>? color;
  final String balance;
  final String received;
  final String sent;

  const CustomHeaderWidget({
    super.key,
    required this.title,
    this.iconPath,
    this.color,
    required this.balance,
    required this.received,
    required this.sent,
  });

  @override
  State<CustomHeaderWidget> createState() => _CustomHeaderWidgetState();
}

class _CustomHeaderWidgetState extends State<CustomHeaderWidget> {
  bool _isBalanceVisible = true;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
  }

  void _toggleBalanceVisibility() {
    setState(() {
      _isBalanceVisible = !_isBalanceVisible;
    });
  }

  String _getBalanceMask() {
    return "***,***";
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 64, bottom: 16),
      // margin: const EdgeInsets.symmetric(horizontal: 8),
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors:
              widget.color ??
              [
                AppColors.darkBgCard,
                AppColors.darkBgSheet,
                AppColors.darkBgHover,
              ],
          end: Alignment.topLeft,
          begin: Alignment.bottomRight,
          stops: const [0.0, 0.15, 1.0],
          tileMode: TileMode.repeated,
        ),
        // border: Border.all(color: AppColors.borderColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Wallet Icon
          Row(
            // mainAxisAlignment: MainAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: widget.iconPath == null ? 24 : 32,
                backgroundColor: widget.iconPath == null
                    ? AppColors.darkBgHover
                    : Colors.white60,
                child: SvgPicture.asset(
                  widget.iconPath ?? AppAssets.walletIcon,
                  width: widget.iconPath == null ? 24 : 30,
                  height: widget.iconPath == null ? 24 : 30,
                  colorFilter: widget.iconPath == null
                      ? ColorFilter.mode(Colors.white, BlendMode.srcIn)
                      : null,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 26,
                    color: AppColors.darkTextPrimary,
                    fontWeight: FontWeight.bold,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          Row(
            // spacing: -8,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                "Total Balance",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w100),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  // todo: implement toggle visibility
                  _toggleBalanceVisibility();
                  
                },
                child: Icon(
                  _isBalanceVisible
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  size: 16,
                  color: AppColors.bgIcon,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "${(_isBalanceVisible ? widget.balance : _getBalanceMask())} ETB",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
            ],
          ),

          // simple stat
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: CustomStatCardWidget(
                  text: "Received",
                  amount:
                      "${(_isBalanceVisible ? widget.received : _getBalanceMask())}",
                  iconPath: AppAssets.arrowUpwardIcon,
                  isReceived: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CustomStatCardWidget(
                  text: "Sent",
                  amount:
                      "${(_isBalanceVisible ? widget.sent : _getBalanceMask())}",
                  iconPath: AppAssets.arrowUpwardIcon,
                  isReceived: false,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
