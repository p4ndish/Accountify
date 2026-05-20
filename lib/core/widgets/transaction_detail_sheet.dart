import 'package:accountify/core/database/database.dart';
import 'package:accountify/core/providers/database_provider.dart';
import 'package:accountify/core/theme/colors.dart';
import 'package:accountify/core/utils/formatters.dart';
import 'package:accountify/core/utils/images.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:url_launcher/url_launcher.dart';

/// Bottom sheet for viewing transaction details with URL support
class TransactionDetailSheet extends StatefulWidget {
  final TransactionWithBank transactionWithBank;
  final Function(String tag)? onTagSelected;

  const TransactionDetailSheet({
    super.key,
    required this.transactionWithBank,
    this.onTagSelected,
  });

  @override
  State<TransactionDetailSheet> createState() => _TransactionDetailSheetState();
}

class _TransactionDetailSheetState extends State<TransactionDetailSheet> {
  String? _selectedTag;

  final List<Map<String, dynamic>> _availableTags = [
    {'name': 'utility', 'icon': Icons.electrical_services, 'color': Colors.orange},
    {'name': 'transfer', 'icon': Icons.swap_horiz, 'color': Colors.blue},
    {'name': 'bills', 'icon': Icons.receipt_long, 'color': Colors.purple},
    {'name': 'food', 'icon': Icons.restaurant, 'color': Colors.green},
    {'name': 'shopping', 'icon': Icons.shopping_bag, 'color': Colors.pink},
    {'name': 'transport', 'icon': Icons.directions_car, 'color': Colors.teal},
    {'name': 'entertainment', 'icon': Icons.movie, 'color': Colors.red},
    {'name': 'health', 'icon': Icons.local_hospital, 'color': Colors.cyan},
  ];

  @override
  void initState() {
    super.initState();
    _selectedTag = widget.transactionWithBank.transaction.tag;
  }

  Future<void> _openUrl(String url) async {
    if (url.isEmpty) return;
    
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.inAppWebView);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open URL')),
        );
      }
    }
  }

  Future<void> _copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Copied to clipboard')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final transaction = widget.transactionWithBank.transaction;
    final bank = widget.transactionWithBank.bank;
    final isDebit = transaction.transactionType.toLowerCase() == 'debited';
    final hasUrl = transaction.paymentLink.isNotEmpty;

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.darkBgCard,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade600,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: isDebit
                          ? AppColors.darkBgSent
                          : AppColors.darkBgReceived,
                      child: SvgPicture.asset(
                        isDebit
                            ? AppAssets.arrowDownwardIcon
                            : AppAssets.arrowUpwardIcon,
                        colorFilter: ColorFilter.mode(
                          isDebit ? AppColors.bgSent : AppColors.bgReceived,
                          BlendMode.srcIn,
                        ),
                        width: 24,
                        height: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isDebit ? 'Money Sent' : 'Money Received',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.darkTextSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${isDebit ? "-" : "+"}${Formatters.formatCurrency(transaction.amount)} ETB',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: isDebit
                                  ? AppColors.darkTextSent
                                  : AppColors.darkTextReceived,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // Transaction Details
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  children: [
                    // Bank Info
                    _buildDetailRow('Bank', bank.name),
                    _buildDetailRow('Account', bank.accountNumber),
                    const SizedBox(height: 16),

                    // Transaction Info
                    _buildDetailRow(
                      'Transaction Type',
                      isDebit ? 'Debit (Sent)' : 'Credit (Received)',
                    ),
                    _buildDetailRow(
                      'Date',
                      Formatters.formatDateTime(transaction.date),
                    ),
                    _buildDetailRow(
                      'Reference Code',
                      transaction.referenceCode,
                      isCopyable: true,
                      onCopy: () => _copyToClipboard(transaction.referenceCode),
                    ),
                    const SizedBox(height: 16),

                    // Current Tag
                    if (_selectedTag != null) ...[
                      _buildDetailRow('Current Tag', _selectedTag!.toUpperCase()),
                      const SizedBox(height: 16),
                    ],

                    // Tag Selection
                    Text(
                      'Select Tag',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.darkTextSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _availableTags.map((tag) {
                        final isSelected = _selectedTag == tag['name'];
                        return ActionChip(
                          avatar: Icon(
                            tag['icon'],
                            size: 18,
                            color: isSelected ? Colors.white : tag['color'],
                          ),
                          label: Text(
                            tag['name'].toString().toUpperCase(),
                            style: TextStyle(
                              fontSize: 12,
                              color: isSelected ? Colors.white : Colors.white70,
                            ),
                          ),
                          backgroundColor: isSelected
                              ? tag['color']
                              : AppColors.darkBgHover,
                          side: BorderSide(
                            color: isSelected
                                ? tag['color']
                                : Colors.transparent,
                          ),
                          onPressed: () {
                            setState(() {
                              _selectedTag = tag['name'];
                            });
                            widget.onTagSelected?.call(tag['name']);
                          },
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 24),

                    // Read More Button (if URL exists)
                    if (hasUrl) ...[
                      Text(
                        'Transaction Receipt',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.darkTextSecondary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: () => _openUrl(transaction.paymentLink),
                        icon: const Icon(Icons.open_in_new),
                        label: const Text('View Receipt'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryBrand,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: () => _copyToClipboard(transaction.paymentLink),
                        icon: const Icon(Icons.copy, size: 16),
                        label: const Text('Copy URL'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.darkTextSecondary,
                        ),
                      ),
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.darkBgHover,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: AppColors.darkTextSecondary,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'No receipt URL available for this transaction',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.darkTextSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(
    String label,
    String value, {
    bool isCopyable = false,
    VoidCallback? onCopy,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.darkTextSecondary,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (isCopyable)
                  IconButton(
                    icon: const Icon(Icons.copy, size: 18),
                    onPressed: onCopy,
                    color: AppColors.darkTextSecondary,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Provider for updating transaction tags
final updateTransactionTagProvider =
    FutureProvider.family<void, ({int transactionId, String tag})>(
  (ref, params) async {
    final db = ref.read(appDatabaseProvider);
    await (db.update(db.transactions)
          ..where((t) => t.id.equals(params.transactionId)))
        .write(TransactionsCompanion(tag: Value(params.tag)));
  },
);
