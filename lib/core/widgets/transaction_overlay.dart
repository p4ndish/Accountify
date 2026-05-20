import 'package:accountify/core/theme/colors.dart';
import 'package:flutter/material.dart';

/// Overlay widget that displays transaction details when an SMS is received
class TransactionOverlay extends StatefulWidget {
  final String bankName;
  final double amount;
  final bool isCredit;
  final String? senderOrRecipient;
  final VoidCallback? onTap;
  final VoidCallback? onDismiss;

  const TransactionOverlay({
    super.key,
    required this.bankName,
    required this.amount,
    required this.isCredit,
    this.senderOrRecipient,
    this.onTap,
    this.onDismiss,
  });

  @override
  State<TransactionOverlay> createState() => _TransactionOverlayState();
}

class _TransactionOverlayState extends State<TransactionOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _controller.forward();

    // Auto dismiss after 4 seconds
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        _dismiss();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _dismiss() async {
    await _controller.reverse();
    widget.onDismiss?.call();
  }

  @override
  Widget build(BuildContext context) {
    final isCredit = widget.isCredit;
    final amountColor = isCredit ? AppColors.darkTextReceived : AppColors.darkTextSent;
    final iconBgColor = isCredit
        ? AppColors.darkTextReceived.withValues(alpha: 0.2)
        : AppColors.darkTextSent.withValues(alpha: 0.2);

    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: GestureDetector(
              onTap: () {
                _dismiss();
                widget.onTap?.call();
              },
              onVerticalDragEnd: (details) {
                if (details.primaryVelocity != null && details.primaryVelocity! < 0) {
                  _dismiss();
                }
              },
              child: Material(
                color: Colors.transparent,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.darkBgCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: amountColor.withValues(alpha: 0.3),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Icon
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: iconBgColor,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isCredit ? Icons.arrow_downward : Icons.arrow_upward,
                          color: amountColor,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Transaction info
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isCredit ? 'Money Received' : 'Money Sent',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.darkTextSecondary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${isCredit ? '+' : '-'}ETB ${widget.amount.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: amountColor,
                              ),
                            ),
                            if (widget.senderOrRecipient != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                '${isCredit ? 'From' : 'To'}: ${widget.senderOrRecipient}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.darkTextSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                      // Bank name badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.darkBgSheet,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          widget.bankName,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: AppColors.darkTextSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Controller to manage showing transaction overlays
class TransactionOverlayController {
  static OverlayEntry? _currentOverlay;

  static void show({
    required BuildContext context,
    required String bankName,
    required double amount,
    required bool isCredit,
    String? senderOrRecipient,
    VoidCallback? onTap,
  }) {
    // Dismiss any existing overlay
    dismiss();

    final overlay = Overlay.of(context);

    _currentOverlay = OverlayEntry(
      builder: (context) => Positioned(
        top: 0,
        left: 0,
        right: 0,
        child: TransactionOverlay(
          bankName: bankName,
          amount: amount,
          isCredit: isCredit,
          senderOrRecipient: senderOrRecipient,
          onTap: () {
            dismiss();
            onTap?.call();
          },
          onDismiss: dismiss,
        ),
      ),
    );

    overlay.insert(_currentOverlay!);
  }

  static void dismiss() {
    _currentOverlay?.remove();
    _currentOverlay = null;
  }
}
