// lib/features/banks/screens/transaction_detail_screen.dart

import 'package:accountify/core/database/database.dart';
import 'package:accountify/core/providers/database_provider.dart';
import 'package:accountify/core/services/background_sms_service.dart';
import 'package:accountify/core/widgets/transaction_metadata_bottom_sheet.dart';
import 'package:accountify/core/widgets/transitions/modal_transitions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// Transaction detail screen for Accountify
class TransactionDetailScreen extends ConsumerWidget {
  const TransactionDetailScreen({
    super.key,
    required this.transaction,
  });

  final Transaction transaction;

  static const Color _blue200 = Color(0xFF90CAF9);
  static const Color _blue50 = Color(0xFFE3F2FD);
  static const Color _blue700 = Color(0xFF1976D2);
  static const Color _green50 = Color(0xFFE8F5E9);
  static const Color _green600 = Color(0xFF43A047);
  static const Color _green700 = Color(0xFF388E3C);
  // Colors
  static const Color _greenColor = Color(0xFF2E7D32);

  static const Color _red50 = Color(0xFFFFEBEE);
  static const Color _red600 = Color(0xFFE53935);
  static const Color _red700 = Color(0xFFD32F2F);
  static const Color _redColor = Color(0xFFC62828);

  // Debug: Print transaction data on creation
  void _debugPrintTransaction() {
    debugPrint('=== Transaction Detail Data ===');
    debugPrint('ID: ${transaction.id}');
    debugPrint('Name: ${transaction.name}');
    debugPrint('Amount: ${transaction.amount}');
    debugPrint('Type: ${transaction.transactionType}');
    debugPrint('SubType: ${transaction.subType}');
    debugPrint('Ref: ${transaction.referenceCode}');
    debugPrint('Balance After: ${transaction.balanceAfter}');
    debugPrint('Date: ${transaction.date}');
    debugPrint('================================');
  }

  // ===========================================================================
  // HERO SECTION
  // ===========================================================================
  Widget _buildHeroSection(ThemeData theme, bool isCredit, String subType) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 24),
      child: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Icon Circle
            _buildIconCircle(isCredit, subType),
            
            const SizedBox(height: 12),
            
            // Amount
            Text(
              _formatAmountDisplay(isCredit),
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w500,
                color: isCredit ? _greenColor : _redColor,
              ),
            ),
            
            // const SizedBox(height: 4),
            
            // Subtitle label
            // Text(
            //   _getSubtitleLabel(subType, isCredit),
            //   style: TextStyle(
            //     fontSize: 13,
            //     color: theme.colorScheme.onSurfaceVariant,
            //   ),
            // ),
            
            const SizedBox(height: 10),
            
            // Date
            Text(
              _formatDate(transaction.date),
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.outline,
              ),
            ),
            
            const SizedBox(height: 10),
            
            // Status Pill
            _buildStatusPill(isCredit),
          ],
        ),
      ),
    );
  }

  Widget _buildIconCircle(bool isCredit, String subType) {
    Color bgColor;
    Color iconColor;
    IconData iconData;
    double iconSize;

    if (isCredit) {
      bgColor = _green50;
      iconColor = _green600;
      iconData = Icons.arrow_downward;
      iconSize = 24;
    } else {
      bgColor = _red50;
      iconColor = _red600;
      iconSize = 22;
      
      switch (subType) {
        case 'package':
          iconData = Icons.data_usage;
          break;
        case 'airtime':
          iconData = Icons.signal_cellular_alt;
          break;
        case 'bank_out':
          iconData = Icons.account_balance;
          break;
        default:
          iconData = Icons.arrow_upward;
          iconSize = 24;
      }
    }

    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
      ),
      child: Icon(
        iconData,
        color: iconColor,
        size: iconSize,
      ),
    );
  }

  String _formatAmountDisplay(bool isCredit) {
    final sign = isCredit ? '+' : '−';
    return '$sign ETB ${NumberFormat('#,##0.00').format(transaction.amount)}';
  }

  String _getSubtitleLabel(String subType, bool isCredit) {
    final name = transaction.name;
    
    if (isCredit) {
      switch (subType) {
        case 'bank_in':
          return 'Received from $name';
        case 'p2p':
        default:
          return 'Received from $name';
      }
    } else {
      switch (subType) {
        case 'bank_out':
          return 'Sent to $name';
        case 'p2p':
          return 'Sent to $name';
        case 'package':
          return name; // Package name IS the label
        case 'airtime':
          return 'Airtime · $name'; // Name holds phone number
        default:
          return 'Sent to $name';
      }
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat("EEE, d MMM yyyy · h:mm a").format(date);
  }

  Widget _buildStatusPill(bool isCredit) {
    final bgColor = isCredit ? _green50 : _red50;
    final textColor = isCredit ? _green700 : _red700;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: textColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            'Completed',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // TRANSACTION INFO SECTION
  // ===========================================================================
  Widget _buildTransactionInfoSection(ThemeData theme, bool isCredit, String subType) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Padding(
          padding: const EdgeInsets.only(top: 16, left: 20, right: 20, bottom: 10),
          child: Text(
            'TRANSACTION INFO',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.outline,
              letterSpacing: 0.06 * 11, // 0.06em
            ),
          ),
        ),
        
        // Info Rows based on subType
        ..._buildInfoRows(theme, isCredit, subType),
      ],
    );
  }

  List<Widget> _buildInfoRows(ThemeData theme, bool isCredit, String subType) {
    final rows = <_InfoRowData>[];
    
    if (isCredit) {
      switch (subType) {
        case 'bank_in':
          rows.add(_InfoRowData('From', transaction.name));
          rows.add(_InfoRowData('To account', '251953511050', isMono: true));
          rows.add(_InfoRowData('Type', 'Bank → telebirr'));
          rows.add(_InfoRowData('Reference', transaction.referenceCode, isMono: true));
          break;
        case 'p2p':
        default:
          rows.add(_InfoRowData('From', transaction.name));
          rows.add(_InfoRowData('Phone', _maskPhone(transaction.name), isMono: true));
          rows.add(_InfoRowData('Type', 'telebirr transfer'));
          rows.add(_InfoRowData('Reference', transaction.referenceCode, isMono: true));
          break;
      }
    } else {
      switch (subType) {
        case 'bank_out':
          rows.add(_InfoRowData('To bank', transaction.name));
          rows.add(_InfoRowData('Account no.', '1000157013347', isMono: true));
          rows.add(_InfoRowData('Type', 'telebirr → bank'));
          rows.add(_InfoRowData('Telebirr ref', transaction.referenceCode, isMono: true));
          if (transaction.secondaryReferenceCode.isNotEmpty) {
            rows.add(_InfoRowData('Bank ref', transaction.secondaryReferenceCode, isMono: true));
          }
          break;
        case 'package':
          rows.add(_InfoRowData('Package', transaction.name));
          rows.add(_InfoRowData('For number', '251953511050', isMono: true));
          rows.add(_InfoRowData('Type', 'Package purchase'));
          rows.add(_InfoRowData('Reference', transaction.referenceCode, isMono: true));
          break;
        case 'airtime':
          rows.add(_InfoRowData('Recharged for', transaction.name, isMono: true));
          rows.add(_InfoRowData('Type', 'Airtime recharge'));
          rows.add(_InfoRowData('Reference', transaction.referenceCode, isMono: true));
          break;
        case 'p2p':
        default:
          rows.add(_InfoRowData('To', transaction.name));
          rows.add(_InfoRowData('Phone', _maskPhone(transaction.name), isMono: true));
          rows.add(_InfoRowData('Type', 'telebirr transfer'));
          rows.add(_InfoRowData('Reference', transaction.referenceCode, isMono: true));
          break;
      }
    }
    
    return rows.asMap().entries.map((entry) {
      final index = entry.key;
      final data = entry.value;
      final isLast = index == rows.length - 1;
      
      return _InfoRow(
        label: data.label,
        value: data.value,
        isMono: data.isMono,
        showDivider: !isLast,
      );
    }).toList();
  }

  String _maskPhone(String name) {
    // Extract phone from name if it contains masked format like 2519****7787
    // For now, return a placeholder - in real app, store phone separately
    return '2519****0093';
  }

  // ===========================================================================
  // FEE BREAKDOWN SECTION
  // ===========================================================================
  Widget _buildFeeBreakdownSection(ThemeData theme) {
    final amount = transaction.amount;
    final fee = transaction.fee;
    final feeVat = transaction.feeVat;
    final total = amount + fee + feeVat;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Padding(
          padding: const EdgeInsets.only(top: 16, left: 20, right: 20, bottom: 10),
          child: Text(
            'FEE BREAKDOWN',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.outline,
              letterSpacing: 0.06 * 11,
            ),
          ),
        ),
        
        // Fee rows
        _FeeRow(
          label: 'Amount sent',
          value: 'ETB ${NumberFormat('#,##0.00').format(amount)}',
        ),
        _FeeRow(
          label: 'Service fee',
          value: 'ETB ${NumberFormat('#,##0.00').format(fee)}',
        ),
        _FeeRow(
          label: '15% VAT',
          value: 'ETB ${NumberFormat('#,##0.00').format(feeVat)}',
        ),
        
        // Total row with border
        Container(
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: theme.dividerColor, width: 0.5),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total deducted',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                Text(
                  'ETB ${NumberFormat('#,##0.00').format(total)}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // BALANCE CARD
  // ===========================================================================
  Widget _buildBalanceCard(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(top: 8, left: 20, right: 20),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Balance after transaction',
            style: TextStyle(
              fontSize: 11,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'ETB ${NumberFormat('#,##0.00').format(transaction.balanceAfter)}',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // ACTION BUTTONS
  // ===========================================================================
  Widget _buildActionButtons(ThemeData theme) {
    final hasReceipt = transaction.paymentLink.isNotEmpty;
    
    return Padding(
      padding: const EdgeInsets.only(top: 16, left: 20, right: 20, bottom: 4),
      child: Row(
        children: [
          if (hasReceipt) ...[
            Expanded(
              child: _ActionButton(
                label: 'View receipt ↗',
                backgroundColor: _blue50,
                foregroundColor: _blue700,
                borderColor: _blue200,
                onTap: () => _launchUrl(transaction.paymentLink),
              ),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: _ActionButton(
              label: 'Share',
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              foregroundColor: theme.colorScheme.onSurface,
              borderColor: theme.dividerColor,
              onTap: _shareTransaction,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _shareTransaction() {
    final dateStr = DateFormat("EEE, d MMM yyyy · h:mm a").format(transaction.date);
    Share.share(
      'Transaction ${transaction.referenceCode}\n'
      'Amount: ETB ${NumberFormat('#,##0.00').format(transaction.amount)}\n'
      'Date: $dateStr',
    );
  }

  Widget _buildMetadataSection(
    BuildContext context,
    WidgetRef ref,
    TransactionMetadata? metadata,
  ) {
    final tags = metadata?.tags ?? const <String>[];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'NOTES',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.outline,
              letterSpacing: 0.06 * 11,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            metadata?.reason ?? 'No reason saved',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          if (tags.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final tag in tags)
                  Chip(label: Text(tag)),
              ],
            )
          else
            Text(
              'No tags saved',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () async {
                await context.showSmoothBottomSheet(
                  child: TransactionMetadataBottomSheet(
                    transactionId: transaction.id,
                    title: transaction.name,
                    subtitle:
                        '${transaction.transactionType == 'debited' ? '-' : '+'}ETB ${transaction.amount.toStringAsFixed(2)}',
                    predefinedTags: BackgroundSmsService.promptTags,
                  ),
                  initialChildSize: 0.65,
                  minChildSize: 0.65,
                  maxChildSize: 0.9,
                );
                ref.invalidate(transactionMetadataProvider(transaction.id));
              },
              child: const Text('Edit reason and tags'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    _debugPrintTransaction();
    debugPrint('TransactionDetailScreen building...');

    final theme = Theme.of(context);
    final isCredit = transaction.transactionType == 'credited';
    final subType = transaction.subType.isEmpty ? 'p2p' : transaction.subType;
    final metadata = ref.watch(transactionMetadataProvider(transaction.id));

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Transaction details',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, size: 20),
            onPressed: () => Navigator.pop(context),
            padding: EdgeInsets.zero,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Section
            _buildHeroSection(theme, isCredit, subType),
            
            // Divider
            Divider(height: 1, thickness: 0.5, color: theme.dividerColor),
            
            // Transaction Info Section
            _buildTransactionInfoSection(theme, isCredit, subType),
            
            // Fee Breakdown Section (only if fee > 0)
            if (transaction.fee > 0)
              _buildFeeBreakdownSection(theme),
            
            // Balance Card
            _buildBalanceCard(theme),

            metadata.when(
              data: (value) => _buildMetadataSection(context, ref, value),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),

            // Action Buttons
            _buildActionButtons(theme),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// HELPER DATA CLASS
// =============================================================================
class _InfoRowData {
  _InfoRowData(this.label, this.value, {this.isMono = false});

  final bool isMono;
  final String label;
  final String value;
}

// =============================================================================
// INFO ROW WIDGET
// =============================================================================
class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    this.isMono = false,
    this.showDivider = true,
  });

  final bool isMono;
  final String label;
  final bool showDivider;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 3,
                child: Text(
                  value,
                  textAlign: TextAlign.end,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: isMono ? 11 : 13,
                    fontWeight: isMono ? FontWeight.normal : FontWeight.w500,
                    color: isMono ? theme.colorScheme.onSurfaceVariant : theme.colorScheme.onSurface,
                    fontFamily: isMono ? 'monospace' : null,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          Divider(height: 0.5, thickness: 0.5, color: theme.dividerColor, indent: 20, endIndent: 20),
      ],
    );
  }
}

// =============================================================================
// FEE ROW WIDGET
// =============================================================================
class _FeeRow extends StatelessWidget {
  const _FeeRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// ACTION BUTTON WIDGET
// =============================================================================
class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.borderColor,
    required this.onTap,
  });

  final Color backgroundColor;
  final Color borderColor;
  final Color foregroundColor;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: Material(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: borderColor, width: 0.5),
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: foregroundColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
