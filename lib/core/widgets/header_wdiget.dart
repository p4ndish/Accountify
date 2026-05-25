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
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: MediaQuery.of(context).padding.top + 16,
        bottom: 16,
      ),
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: widget.color != null
            ? LinearGradient(
                colors: widget.color!,
                end: Alignment.topLeft,
                begin: Alignment.bottomRight,
                stops: const [0.0, 0.15, 1.0],
                tileMode: TileMode.repeated,
              )
            : null,
        color: widget.color == null ? colorScheme.surfaceContainerHighest : null,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Wallet Icon
          Row(
            children: [
              CircleAvatar(
                radius: widget.iconPath == null ? 24 : 32,
                backgroundColor: widget.iconPath == null
                    ? colorScheme.onSurface.withValues(alpha: 0.08)
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
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                "Total Balance",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w100,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _toggleBalanceVisibility,
                child: Icon(
                  _isBalanceVisible
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  size: 16,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            "${(_isBalanceVisible ? widget.balance : _getBalanceMask())} ETB",
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
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
                  iconPath: AppAssets.arrowDownwardIcon,
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
