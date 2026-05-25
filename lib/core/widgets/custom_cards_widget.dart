import 'dart:ui';

import 'package:accountify/core/database/database.dart';
import 'package:accountify/core/providers/database_provider.dart';
import 'package:accountify/core/utils/formatters.dart';
import 'package:accountify/core/utils/images.dart';
import 'package:accountify/core/widgets/header_wdiget.dart';
import 'package:accountify/core/widgets/loading/loading_overlay.dart';
import 'package:accountify/core/widgets/transitions/animated_list_builder.dart';
import 'package:accountify/core/widgets/transitions/page_transitions.dart';
import 'package:accountify/features/banks/screens/transaction_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';

class CustomCardWidget extends StatelessWidget {
  final String title;
  final String subTitle;
  final String? amount;
  final String? icon;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final bool? isIconTransparent;
  final Color? cardColor;
  final bool isGlass;
  const CustomCardWidget({super.key, required this.title, required this.subTitle, this.amount, this.icon, this.isIconTransparent=false, required this.onTap, this.onLongPress, this.cardColor, this.isGlass = false});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bgColor = cardColor ?? colorScheme.surfaceContainerHighest;

    if (isGlass) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      final glassTint = isDark
          ? const Color(0xFF1E293B).withValues(alpha: 0.55)
          : const Color(0xFFE2E8F0).withValues(alpha: 0.5);
      final highlightColor = isDark
          ? Colors.white.withValues(alpha: 0.12)
          : Colors.white.withValues(alpha: 0.7);
      final borderColor = isDark
          ? Colors.white.withValues(alpha: 0.15)
          : Colors.white.withValues(alpha: 0.5);

      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            child: GestureDetector(
              onLongPress: onLongPress,
              child: InkWell(
              borderRadius: BorderRadius.circular(16),
              splashColor: Colors.white.withValues(alpha: 0.1),
              highlightColor: Colors.white.withValues(alpha: 0.05),
              onTap: onTap,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: glassTint,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: borderColor,
                    width: 1,
                  ),
                ),
                child: Stack(
                  children: [
                    // Liquid glass highlight streak
                    Positioned(
                      top: -2,
                      left: 16,
                      right: 60,
                      child: Container(
                        height: 1.2,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              highlightColor,
                              Colors.transparent,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    // Secondary glow at bottom
                    Positioned(
                      bottom: -1,
                      left: 40,
                      right: 40,
                      child: Container(
                        height: 0.8,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              highlightColor.withValues(alpha: 0.3),
                              Colors.transparent,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    // Content
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      spacing: 4,
                      children: [
                        Expanded(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.start,
                            spacing: 8,
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: colorScheme.onSurface.withValues(alpha: 0.06),
                                child: (icon?.isNotEmpty ?? false)
                                    ? SvgPicture.asset(icon!, width: 32, height: 32)
                                    : Icon(Icons.person, size: 28, color: colorScheme.onSurface),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  spacing: 2,
                                  children: [
                                    Text(
                                      title,
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: colorScheme.onSurface,
                                      ),
                                    ),
                                    Text(
                                      subTitle.isEmpty ? 'Tap & hold to add account no.' : subTitle,
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: subTitle.isEmpty
                                            ? colorScheme.onSurfaceVariant.withValues(alpha: 0.5)
                                            : colorScheme.onSurfaceVariant,
                                        fontStyle: subTitle.isEmpty ? FontStyle.italic : null,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (amount != null)
                          Text(
                            amount!,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                      ],
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

    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(12),
      child: GestureDetector(
        onLongPress: onLongPress,
        child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            spacing: 4,
            children: [
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.start,
                  spacing: 8,
                  children: [
                    // icon
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: isIconTransparent == true
                          ? bgColor
                          : colorScheme.onSurface.withValues(alpha: 0.08),
                      child: (icon?.isNotEmpty ?? false)
                          ? SvgPicture.asset(
                              icon!,
                              width: 32,
                              height: 32,
                            )
                          : Icon(Icons.person, size: 28, color: colorScheme.onSurface),
                    ),

                    // bank or wallet name with number
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        spacing: 2,
                        children: [
                          Text(
                            title,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          Text(
                            subTitle.isEmpty ? 'Tap & hold to add account no.' : subTitle,
                            style: TextStyle(
                              fontSize: 10,
                              color: subTitle.isEmpty
                                  ? colorScheme.onSurfaceVariant.withValues(alpha: 0.5)
                                  : colorScheme.onSurfaceVariant,
                              fontStyle: subTitle.isEmpty ? FontStyle.italic : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.end,
                spacing: 12,
                children: [
                  // balance
                  if (amount?.isNotEmpty == true)
                    Text(
                      amount!,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),

                  // button >
                  Icon(Icons.arrow_forward_ios, size: 16, color: colorScheme.onSurfaceVariant),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
    );
  }
}

class BankTransactionBottomSheet extends ConsumerStatefulWidget {
  final Bank bank;
  const BankTransactionBottomSheet({super.key, required this.bank});

  @override
  ConsumerState<BankTransactionBottomSheet> createState() => _BankTransactionBottomSheetState();
}

class _BankTransactionBottomSheetState extends ConsumerState<BankTransactionBottomSheet> {
  @override
  Widget build(BuildContext context) {
    final transactions = ref.watch(transactionsWithBankListProvider(widget.bank.id));
    final colorScheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: Stack(
        children: [
          ListView(
            primary: true,
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              CustomHeaderWidget(
                title: widget.bank.name,
                iconPath: widget.bank.icon.isNotEmpty ? widget.bank.icon : null,
                color: const [Color(0xFF023841), Color(0xFF022C33), Color(0xDF336B7A)],
                balance: Formatters.formatCurrency(widget.bank.balance.abs()),
                received: Formatters.formatCurrency(widget.bank.received),
                sent: Formatters.formatCurrency(widget.bank.sent),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Text(
                  'Transactions',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              transactions.when(
                data: (data) => SimpleListBuilder(
                  items: data,
                  itemBuilder: (context, row, index) {
                    final isDebit =
                        row.transaction.transactionType.toLowerCase() == 'debited';
                    final formattedDate =
                        DateFormat('MMM dd, yyyy').format(row.transaction.date);
                    final formattedAmount =
                        NumberFormat('#,##0.00').format(row.transaction.amount);

                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      child: CustomTransactionCardWidget(
                        isDebit: isDebit,
                        amount: row.transaction.amount,
                        formattedAmount:
                            '${isDebit ? '-' : '+'}$formattedAmount Br',
                        date: formattedDate,
                        bank: row.bank.name,
                        onTap: () {
                          context.pushScale(
                            TransactionDetailScreen(transaction: row.transaction),
                          );
                        },
                      ),
                    );
                  },
                ),
                loading: () => const SkeletonList(itemCount: 5),
                error: (error, stack) => Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    'Failed to load transactions: $error',
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            top: 16,
            right: 16,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: CircleAvatar(
                radius: 20,
                backgroundColor: colorScheme.onSurface.withValues(alpha: 0.1),
                child: Icon(
                  Icons.close,
                  size: 20,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CustomTransactionCardWidget extends StatelessWidget {
  final bool isDebit;
  final double amount;
  final String? formattedAmount;
  final String date;
  final String bank;
  final VoidCallback? onTap;
  const CustomTransactionCardWidget({
    super.key,
    required this.isDebit,
    required this.amount,
    this.formattedAmount,
    required this.date,
    required this.bank,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final receivedColor = colorScheme.onPrimaryContainer;
    final sentColor = colorScheme.onErrorContainer;

    return Material(
      color: colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: colorScheme.onSurface.withValues(alpha: 0.04),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            spacing: 8,
            children: [
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.start,
                  spacing: 8,
                  children: [
                    // icon
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: isDebit
                          ? colorScheme.errorContainer
                          : colorScheme.primaryContainer,
                      child: SvgPicture.asset(
                        isDebit
                            ? AppAssets.arrowDownwardIcon
                            : AppAssets.arrowUpwardIcon,
                        colorFilter: ColorFilter.mode(
                          isDebit ? sentColor : receivedColor,
                          BlendMode.srcIn,
                        ),
                        width: 16,
                        height: 16,
                      ),
                    ),

                    // bank or wallet name with number
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        spacing: 2,
                        children: [
                          Text(
                            bank,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          Text(
                            '• $date',
                            style: TextStyle(
                              fontSize: 10,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.end,
                spacing: 12,
                children: [
                  // balance
                  Text(
                    formattedAmount ?? '${isDebit ? "-" : "+"}$amount Br',
                    style: TextStyle(
                      color: isDebit ? sentColor : receivedColor,
                    ),
                  ),

                  // button >
                  Icon(Icons.arrow_forward_ios, size: 16, color: colorScheme.onSurfaceVariant),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}



class CustomTransactionCardSkeletonWidget extends StatefulWidget {
  const CustomTransactionCardSkeletonWidget({
    super.key,
  });

  @override
  State<CustomTransactionCardSkeletonWidget> createState() => _CustomTransactionCardSkeletonWidgetState();
}

class _CustomTransactionCardSkeletonWidgetState extends State<CustomTransactionCardSkeletonWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 4500),
      vsync: this,
    )..repeat(reverse: false);

    _animation = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(0.0, 0.7, curve: Curves.easeInOut),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final shimmerBase = colorScheme.onSurface.withValues(alpha: 0.06);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Material(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  shimmerBase,
                  shimmerBase.withValues(alpha: 0.15),
                  shimmerBase,
                ],
                stops: [
                  (_animation.value - 0.3).clamp(0.0, 1.0),
                  _animation.value.clamp(0.0, 1.0),
                  (_animation.value + 0.3).clamp(0.0, 1.0),
                ],
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              spacing: 8,
              children: [
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.start,
                    spacing: 8,
                    children: [
                      // icon placeholder
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: shimmerBase,
                      ),

                      // text placeholders
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          spacing: 2,
                          children: [
                            Container(
                              height: 14,
                              width: 120,
                              decoration: BoxDecoration(
                                color: shimmerBase,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            SizedBox(height: 4),
                            Container(
                              height: 10,
                              width: 80,
                              decoration: BoxDecoration(
                                color: shimmerBase,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.end,
                  spacing: 12,
                  children: [
                    // balance placeholder
                    Container(
                      height: 14,
                      width: 60,
                      decoration: BoxDecoration(
                        color: shimmerBase,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
