import 'dart:math';

import 'package:accountify/core/database/database.dart';
import 'package:accountify/core/providers/database_provider.dart';
import 'package:accountify/core/theme/colors.dart';
import 'package:accountify/core/theme/theme_provider.dart';
import 'package:accountify/core/widgets/custom_cards_widget.dart';
import 'package:accountify/core/widgets/transitions/modal_transitions.dart';
import 'package:accountify/core/utils/formatters.dart';
import 'package:accountify/features/banks/screens/transaction_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

// =============================================================================
// MONTH SUMMARY MODEL
// =============================================================================
class MonthSummary {
  final String monthKey; // e.g. "2026-01"
  final String label; // e.g. "Jan 26"
  final double totalIn;
  final double totalOut;
  final int countIn;
  final int countOut;

  const MonthSummary({
    required this.monthKey,
    required this.label,
    required this.totalIn,
    required this.totalOut,
    required this.countIn,
    required this.countOut,
  });
}

// =============================================================================
// CATEGORY DATA MODEL
// =============================================================================
class CategoryData {
  final String name;
  final double amount;
  final int count;
  final Color iconColor;
  final Color iconBg;
  final Color barColor;
  final IconData icon;

  const CategoryData({
    required this.name,
    required this.amount,
    required this.count,
    required this.iconColor,
    required this.iconBg,
    required this.barColor,
    required this.icon,
  });
}

// =============================================================================
// INSIGHT SPAN MODEL
// =============================================================================
class InsightSpan {
  final String text;
  final bool isBold;

  const InsightSpan(this.text, {this.isBold = false});
}

// =============================================================================
// MAIN SCREEN
// =============================================================================
class AllBanksScreen extends ConsumerStatefulWidget {
  const AllBanksScreen({super.key});

  @override
  ConsumerState<AllBanksScreen> createState() => _AllBanksScreenState();
}

class _AllBanksScreenState extends ConsumerState<AllBanksScreen> {
  int _periodIndex = 1; // Default to "6M"
  DateTimeRange? _customDateRange;

  final List<String> _periodLabels = ['3M', '6M', '1Y', 'All', 'Custom'];

  DateTime get _cutoff {
    if (_periodIndex == 4 && _customDateRange != null) {
      return _customDateRange!.start;
    }
    final now = DateTime.now();
    switch (_periodIndex) {
      case 0: return now.subtract(const Duration(days: 90));
      case 1: return now.subtract(const Duration(days: 180));
      case 2: return now.subtract(const Duration(days: 365));
      default: return DateTime(2000);
    }
  }

  DateTime? get _endDate {
    if (_periodIndex == 4 && _customDateRange != null) {
      return _customDateRange!.end;
    }
    return null;
  }

  int get _calendarMonths {
    if (_periodIndex == 4 && _customDateRange != null) {
      final start = _customDateRange!.start;
      final end = _customDateRange!.end;
      return max(1, (end.year - start.year) * 12 + end.month - start.month + 1);
    }
    switch (_periodIndex) {
      case 0: return 3;
      case 1: return 6;
      case 2: return 12;
      default: return 1;
    }
  }

  List<TransactionWithBank> _filterTransactions(
    List<TransactionWithBank> transactions,
  ) {
    return transactions.where((t) {
      final date = t.transaction.date;
      if (!date.isAfter(_cutoff)) return false;
      final end = _endDate;
      if (end != null && date.isAfter(end.add(const Duration(days: 1)))) return false;
      return true;
    }).toList();
  }

  List<MonthSummary> _buildMonthlyData(List<TransactionWithBank> transactions) {
    final Map<String, MonthSummary> monthlyMap = {};

    for (final twb in transactions) {
      final txn = twb.transaction;
      final monthKey = DateFormat('yyyy-MM').format(txn.date);
      final monthLabel = DateFormat('MMM yyyy').format(txn.date);
      final isCredit = txn.transactionType.toLowerCase() == 'credited';

      final existing = monthlyMap[monthKey];
      if (existing == null) {
        monthlyMap[monthKey] = MonthSummary(
          monthKey: monthKey,
          label: monthLabel,
          totalIn: isCredit ? txn.amount : 0,
          totalOut: !isCredit ? txn.amount : 0,
          countIn: isCredit ? 1 : 0,
          countOut: !isCredit ? 1 : 0,
        );
      } else {
        monthlyMap[monthKey] = MonthSummary(
          monthKey: monthKey,
          label: existing.label,
          totalIn: existing.totalIn + (isCredit ? txn.amount : 0),
          totalOut: existing.totalOut + (!isCredit ? txn.amount : 0),
          countIn: existing.countIn + (isCredit ? 1 : 0),
          countOut: existing.countOut + (!isCredit ? 1 : 0),
        );
      }
    }

    final sortedKeys = monthlyMap.keys.toList()..sort();
    return sortedKeys.map((k) => monthlyMap[k]!).toList();
  }

  List<CategoryData> _buildCategoryData(List<TransactionWithBank> transactions) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    double packages = 0, p2p = 0, bankTransfers = 0, airtime = 0;
    int packagesCount = 0, p2pCount = 0, bankCount = 0, airtimeCount = 0;

    for (final twb in transactions) {
      final txn = twb.transaction;
      if (txn.transactionType.toLowerCase() != 'debited') continue;

      switch (txn.subType.toLowerCase()) {
        case 'package': packages += txn.amount; packagesCount++; break;
        case 'p2p': p2p += txn.amount; p2pCount++; break;
        case 'bank_out': bankTransfers += txn.amount; bankCount++; break;
        case 'airtime': airtime += txn.amount; airtimeCount++; break;
      }
    }

    final colorScheme = Theme.of(context).colorScheme;
    final categories = [
      CategoryData(
        name: 'Packages', amount: packages, count: packagesCount,
        icon: Icons.data_usage, iconColor: const Color(0xFFFBBF24),
        iconBg: isDark ? const Color(0x33FBBF24) : const Color(0x1FFBBF24),
        barColor: const Color(0xFFFBBF24),
      ),
      CategoryData(
        name: 'P2P transfers', amount: p2p, count: p2pCount,
        icon: Icons.arrow_upward, iconColor: colorScheme.onPrimaryContainer,
        iconBg: colorScheme.primaryContainer, barColor: colorScheme.onPrimaryContainer,
      ),
      CategoryData(
        name: 'Bank transfers', amount: bankTransfers, count: bankCount,
        icon: Icons.account_balance, iconColor: const Color(0xFF60A5FA),
        iconBg: isDark ? const Color(0x2A60A5FA) : const Color(0x1A60A5FA),
        barColor: const Color(0xFF60A5FA),
      ),
      CategoryData(
        name: 'Airtime', amount: airtime, count: airtimeCount,
        icon: Icons.signal_cellular_alt, iconColor: const Color(0xFFA78BFA),
        iconBg: isDark ? const Color(0x2AA78BFA) : const Color(0x1AA78BFA),
        barColor: const Color(0xFFA78BFA),
      ),
    ];

    categories.sort((a, b) => b.amount.compareTo(a.amount));
    return categories.where((c) => c.amount > 0).toList();
  }

  String _formatETB(double v) => NumberFormat('#,##0', 'en_US').format(v);

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _customDateRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _customDateRange = picked;
        _periodIndex = 4;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncTxns = ref.watch(transactionsWithBanksListProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: false,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(12.0),
            bottomRight: Radius.circular(12.0),
          ),
        ),
        scrolledUnderElevation: 0,
        title: const Text('Analytics'),
        actions: [
          Consumer(
            builder: (context, ref, _) {
              final currentTheme = ref.watch(themeProvider);
              return IconButton(
                icon: Icon(currentTheme == AppThemeMode.dark ? Icons.light_mode : Icons.dark_mode),
                onPressed: () => ref.read(themeProvider.notifier).toggleTheme(),
              );
            },
          ),
        ],
      ),
      body: asyncTxns.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
        data: (transactions) {
          final filtered = _filterTransactions(transactions);
          final monthlyData = _buildMonthlyData(filtered);
          final categoryData = _buildCategoryData(filtered);

          final totalIn = filtered
              .where((t) => t.transaction.transactionType.toLowerCase() == 'credited')
              .fold<double>(0, (sum, t) => sum + t.transaction.amount);
          final totalOut = filtered
              .where((t) => t.transaction.transactionType.toLowerCase() == 'debited')
              .fold<double>(0, (sum, t) => sum + t.transaction.amount);
          final cntIn = filtered
              .where((t) => t.transaction.transactionType.toLowerCase() == 'credited')
              .length;
          final cntOut = filtered
              .where((t) => t.transaction.transactionType.toLowerCase() == 'debited')
              .length;

          final latestBalance = filtered.isNotEmpty
              ? ([...filtered]..sort((a, b) => a.transaction.date.compareTo(b.transaction.date)))
                  .last.transaction.balanceAfter
              : 0.0;

          final numMonths = monthlyData.isEmpty ? 1 : monthlyData.length;
          final calendarMonths = _calendarMonths;
          final avgPerMonth = totalOut / (calendarMonths > 0 ? calendarMonths : 1);
          final net = totalIn - totalOut;

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Overview card (includes net position)
                _buildOverviewCard(
                  colorScheme: colorScheme,
                  totalIn: totalIn,
                  totalOut: totalOut,
                  currentBal: latestBalance,
                  avgPerMonth: avgPerMonth,
                  cntIn: cntIn,
                  cntOut: cntOut,
                  net: net,
                  numMonths: numMonths,
                  totalTxns: cntIn + cntOut,
                ),
                const SizedBox(height: 12),
                const _SectionHeader(title: 'Monthly flow'),
                const SizedBox(height: 4),
                _buildMonthlyCard(summaries: monthlyData, filtered: filtered),
                const SizedBox(height: 12),
                const _SectionHeader(title: 'Spending by category'),
                const SizedBox(height: 4),
                _buildCategoryCard(categories: categoryData),
                const SizedBox(height: 12),
                const _SectionHeader(title: 'Insights'),
                const SizedBox(height: 4),
                _buildInsightsCard(filtered: filtered, summaries: monthlyData, categories: categoryData),
              ],
            ),
          );
        },
      ),
    );
  }

  // ===========================================================================
  // OVERVIEW CARD (merged with net position)
  // ===========================================================================
  Widget _buildOverviewCard({
    required ColorScheme colorScheme,
    required double totalIn,
    required double totalOut,
    required double currentBal,
    required double avgPerMonth,
    required int cntIn,
    required int cntOut,
    required double net,
    required int numMonths,
    required int totalTxns,
  }) {
    final isPositive = net >= 0;
    final netColor = isPositive ? colorScheme.onPrimaryContainer : colorScheme.onErrorContainer;
    final bgBadge = isPositive ? colorScheme.primaryContainer : colorScheme.errorContainer;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Overview', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: colorScheme.onSurface)),
          const SizedBox(height: 10),
          // Period pills + date picker
          Row(
            children: [
              Expanded(child: _buildPeriodPills()),
            ],
          ),
          // Custom date range display
          if (_periodIndex == 4 && _customDateRange != null) ...[
            const SizedBox(height: 6),
            Center(
              child: Text(
                '${DateFormat('MMM d, y').format(_customDateRange!.start)} – ${DateFormat('MMM d, y').format(_customDateRange!.end)}',
                style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
              ),
            ),
          ],
          const SizedBox(height: 10),
          // 2x2 stat grid
          GridView.count(
            crossAxisCount: 2,
            childAspectRatio: 2.2,
            crossAxisSpacing: 6,
            mainAxisSpacing: 6,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            children: [
              _StatCard(label: 'TOTAL IN', value: totalIn, sub: 'ETB · $cntIn txns', color: colorScheme.onPrimaryContainer),
              _StatCard(label: 'TOTAL OUT', value: totalOut, sub: 'ETB · $cntOut txns', color: colorScheme.error),
              _StatCard(label: 'BALANCE', value: currentBal, sub: 'ETB', color: AppColors.primaryBrand),
              _StatCard(label: 'AVG / MONTH', value: avgPerMonth, sub: 'ETB spent', color: colorScheme.onSurface),
            ],
          ),
          const SizedBox(height: 8),
          // Net position row (merged from separate card)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: colorScheme.outline.withValues(alpha: 0.15), width: 0.5),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('NET POSITION', style: TextStyle(fontSize: 9, color: colorScheme.onSurfaceVariant, letterSpacing: 0.05)),
                    const SizedBox(height: 2),
                    Text(
                      '${isPositive ? "+" : "-"} ETB ${_formatETB(net.abs())}',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: netColor),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: bgBadge,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: netColor.withValues(alpha: 0.3), width: 0.5),
                  ),
                  child: Text(
                    isPositive ? 'Inflow' : 'Outflow',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: netColor),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // PERIOD PILLS (with Custom date picker option)
  // ===========================================================================
  Widget _buildPeriodPills() {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: List.generate(_periodLabels.length, (index) {
        final isActive = _periodIndex == index;
        final isCustom = index == 4;

        return Expanded(
          child: GestureDetector(
            onTap: () {
              if (isCustom) {
                _pickDateRange();
              } else {
                setState(() => _periodIndex = index);
              }
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: isActive ? AppColors.primaryBrand : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isActive ? AppColors.primaryBrand : colorScheme.outline,
                  width: 0.5,
                ),
              ),
              child: isCustom
                  ? Icon(Icons.date_range, size: 14, color: isActive ? Colors.white : colorScheme.onSurfaceVariant)
                  : Text(
                      _periodLabels[index],
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isActive ? FontWeight.w500 : FontWeight.w400,
                        color: isActive ? Colors.white : colorScheme.onSurfaceVariant,
                      ),
                    ),
            ),
          ),
        );
      }),
    );
  }

  // ===========================================================================
  // MONTHLY FLOW CARD (with tappable rows)
  // ===========================================================================
  Widget _buildMonthlyCard({
    required List<MonthSummary> summaries,
    required List<TransactionWithBank> filtered,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    if (summaries.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2), width: 0.5),
        ),
        child: Center(child: Text('No data for selected period', style: TextStyle(color: colorScheme.onSurfaceVariant))),
      );
    }

    final maxVal = summaries
        .map((s) => s.totalIn > s.totalOut ? s.totalIn : s.totalOut)
        .reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Legend
          Row(
            children: [
              Container(width: 8, height: 8, decoration: BoxDecoration(color: colorScheme.onPrimaryContainer, borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 4),
              Text('Money in', style: TextStyle(fontSize: 10, color: colorScheme.onSurfaceVariant)),
              const SizedBox(width: 10),
              Container(width: 8, height: 8, decoration: BoxDecoration(color: colorScheme.onErrorContainer, borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 4),
              Text('Money out', style: TextStyle(fontSize: 10, color: colorScheme.onSurfaceVariant)),
            ],
          ),
          const SizedBox(height: 10),
          ...summaries.asMap().entries.map((entry) {
            final month = entry.value;
            final isLast = entry.key == summaries.length - 1;
            return _MonthBarRow(
              month: month,
              maxVal: maxVal,
              isLast: isLast,
              transactions: filtered,
            );
          }),
        ],
      ),
    );
  }

  // ===========================================================================
  // CATEGORY CARD
  // ===========================================================================
  Widget _buildCategoryCard({required List<CategoryData> categories}) {
    final colorScheme = Theme.of(context).colorScheme;
    final totalSpend = categories.fold<double>(0, (sum, c) => sum + c.amount);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (categories.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(child: Text('No spending data', style: TextStyle(color: colorScheme.onSurfaceVariant))),
            )
          else
            ...categories.asMap().entries.map((entry) {
              final cat = entry.value;
              final isLast = entry.key == categories.length - 1;
              return Column(children: [
                _CategoryRow(category: cat, totalSpend: totalSpend),
                if (!isLast) Divider(height: 1, thickness: 0.5, color: colorScheme.outline.withValues(alpha: 0.2)),
              ]);
            }),
        ],
      ),
    );
  }

  // ===========================================================================
  // INSIGHTS CARD
  // ===========================================================================
  Widget _buildInsightsCard({
    required List<TransactionWithBank> filtered,
    required List<MonthSummary> summaries,
    required List<CategoryData> categories,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final insights = _computeInsights(filtered: filtered, summaries: summaries, categories: categories);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (insights.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(child: Text('No insights yet', style: TextStyle(color: colorScheme.onSurfaceVariant))),
            )
          else
            ...insights.asMap().entries.map((entry) {
              final isLast = entry.key == insights.length - 1;
              return Column(children: [
                _InsightRow(insight: entry.value),
                if (!isLast) Divider(height: 1, thickness: 0.5, color: colorScheme.outline.withValues(alpha: 0.2)),
              ]);
            }),
        ],
      ),
    );
  }

  List<Insight> _computeInsights({
    required List<TransactionWithBank> filtered,
    required List<MonthSummary> summaries,
    required List<CategoryData> categories,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final insights = <Insight>[];

    if (filtered.isEmpty || summaries.isEmpty) return insights;

    final bestIn = summaries.reduce((a, b) => a.totalIn > b.totalIn ? a : b);
    if (bestIn.totalIn > 0) {
      insights.add(Insight(
        spans: [
          const InsightSpan('Best month was '), InsightSpan(bestIn.label, isBold: true),
          const InsightSpan(' — ETB '), InsightSpan(_formatETB(bestIn.totalIn), isBold: true),
          const InsightSpan(' received in '), InsightSpan('${bestIn.countIn}', isBold: true),
          const InsightSpan(' transactions'),
        ],
        dotColor: colorScheme.onPrimaryContainer,
      ));
    }

    final mostOut = summaries.reduce((a, b) => a.totalOut > b.totalOut ? a : b);
    if (mostOut.totalOut > 0) {
      insights.add(Insight(
        spans: [
          const InsightSpan('Highest spending was '), InsightSpan(mostOut.label, isBold: true),
          const InsightSpan(' — ETB '), InsightSpan(_formatETB(mostOut.totalOut), isBold: true),
          const InsightSpan(' across '), InsightSpan('${mostOut.countOut}', isBold: true),
          const InsightSpan(' transactions'),
        ],
        dotColor: colorScheme.onErrorContainer,
      ));
    }

    if (categories.isNotEmpty) {
      final topCat = categories.first;
      final totalSpend = categories.fold<double>(0, (sum, c) => sum + c.amount);
      if (totalSpend > 0) {
        final pct = (topCat.amount / totalSpend * 100).round();
        insights.add(Insight(
          spans: [
            InsightSpan(topCat.name, isBold: true), const InsightSpan(' accounts for '),
            InsightSpan('$pct%', isBold: true), const InsightSpan(' of spending — ETB '),
            InsightSpan(_formatETB(topCat.amount), isBold: true), const InsightSpan(' in '),
            InsightSpan('${topCat.count}', isBold: true), const InsightSpan(' purchases'),
          ],
          dotColor: const Color(0xFFFBBF24),
        ));
      }
    }

    final sortedByAmount = [...filtered]..sort((a, b) => b.transaction.amount.compareTo(a.transaction.amount));
    final largest = sortedByAmount.first;
    insights.add(Insight(
      spans: [
        const InsightSpan('Largest transaction: ETB '), InsightSpan(_formatETB(largest.transaction.amount), isBold: true),
        const InsightSpan(' on '), InsightSpan(DateFormat('MMM d, yyyy').format(largest.transaction.date), isBold: true),
      ],
      dotColor: const Color(0xFF60A5FA),
    ));

    return insights;
  }
}

// =============================================================================
// SECTION HEADER
// =============================================================================
class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(left: 2),
      child: Text(title, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: colorScheme.onSurfaceVariant, letterSpacing: 0.03)),
    );
  }
}

// =============================================================================
// STAT CARD
// =============================================================================
class _StatCard extends StatelessWidget {
  final String label;
  final double value;
  final String sub;
  final Color color;

  const _StatCard({required this.label, required this.value, required this.sub, required this.color});

  String _format(double v) => NumberFormat('#,##0', 'en_US').format(v);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.15), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w500, color: colorScheme.onSurfaceVariant, letterSpacing: 0.04)),
          const SizedBox(height: 2),
          Text('ETB ${_format(value)}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: color), overflow: TextOverflow.ellipsis),
          Text(sub, style: TextStyle(fontSize: 9, color: colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

// =============================================================================
// MONTH BAR ROW (tappable)
// =============================================================================
class _MonthBarRow extends StatelessWidget {
  final MonthSummary month;
  final double maxVal;
  final bool isLast;
  final List<TransactionWithBank> transactions;

  const _MonthBarRow({
    required this.month,
    required this.maxVal,
    required this.isLast,
    required this.transactions,
  });

  String _format(double v) => NumberFormat('#,##0', 'en_US').format(v);

  List<TransactionWithBank> get _monthTransactions {
    return transactions.where((t) => DateFormat('yyyy-MM').format(t.transaction.date) == month.monthKey).toList();
  }

  void _showMonthTransactions(BuildContext context) {
    final monthTxns = _monthTransactions;
    if (monthTxns.isEmpty) return;

    context.showSmoothBottomSheet(
      initialChildSize: 0.6,
      minChildSize: 0.35,
      maxChildSize: 0.95,
      snap: true,
      snapSizes: const [0.35, 0.6, 0.95],
      child: _MonthTransactionsSheet(
        monthLabel: month.label,
        transactions: monthTxns,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 6),
      child: InkWell(
        onTap: () => _showMonthTransactions(context),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(month.label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: colorScheme.onSurface)),
                  Icon(Icons.chevron_right, size: 14, color: colorScheme.onSurfaceVariant),
                ],
              ),
              const SizedBox(height: 3),
              _BarTrack(value: month.totalIn, maxVal: maxVal, color: colorScheme.onPrimaryContainer),
              const SizedBox(height: 2),
              _BarTrack(value: month.totalOut, maxVal: maxVal, color: colorScheme.onErrorContainer),
              const SizedBox(height: 2),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('ETB ${_format(month.totalIn)}', style: TextStyle(fontSize: 10, color: colorScheme.onPrimaryContainer)),
                  Text('ETB ${_format(month.totalOut)}', style: TextStyle(fontSize: 10, color: colorScheme.onErrorContainer)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// MONTH TRANSACTIONS SHEET
// =============================================================================
class _MonthTransactionsSheet extends StatelessWidget {
  final String monthLabel;
  final List<TransactionWithBank> transactions;

  const _MonthTransactionsSheet({required this.monthLabel, required this.transactions});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  monthLabel,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: colorScheme.onSurface),
                ),
                Text(
                  '${transactions.length} transactions',
                  style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              primary: true,
              padding: const EdgeInsets.only(bottom: 24),
              itemCount: transactions.length,
              itemBuilder: (context, index) {
                final twb = transactions[index];
                final txn = twb.transaction;
                final isDebit = txn.transactionType.toLowerCase() == 'debited';
                final formattedDate = DateFormat('MMM dd, yyyy').format(txn.date);
                final formattedAmount = NumberFormat('#,##0.00').format(txn.amount);

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: CustomTransactionCardWidget(
                    isDebit: isDebit,
                    amount: txn.amount,
                    formattedAmount: '${isDebit ? '-' : '+'}$formattedAmount Br',
                    date: formattedDate,
                    bank: twb.bank.name,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TransactionDetailScreen(transaction: txn),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// BAR TRACK
// =============================================================================
class _BarTrack extends StatelessWidget {
  final double value;
  final double maxVal;
  final Color color;

  const _BarTrack({required this.value, required this.maxVal, required this.color});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (ctx, constraints) {
        return Stack(
          children: [
            Container(
              height: 5,
              width: constraints.maxWidth,
              decoration: BoxDecoration(
                color: colorScheme.outline.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(2.5),
              ),
            ),
            Container(
              height: 5,
              width: maxVal == 0 || value == 0
                  ? 0
                  : max(2.0, constraints.maxWidth * (value / maxVal)),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2.5),
              ),
            ),
          ],
        );
      },
    );
  }
}

// =============================================================================
// CATEGORY ROW
// =============================================================================
class _CategoryRow extends StatelessWidget {
  final CategoryData category;
  final double totalSpend;

  const _CategoryRow({required this.category, required this.totalSpend});

  String _format(double v) => NumberFormat('#,##0', 'en_US').format(v);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final pct = totalSpend > 0 ? (category.amount / totalSpend) : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(color: category.iconBg, borderRadius: BorderRadius.circular(8)),
            child: Center(child: Icon(category.icon, size: 16, color: category.iconColor)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(category.name, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: colorScheme.onSurface)),
                Text('${category.count} transactions', style: TextStyle(fontSize: 9, color: colorScheme.onSurfaceVariant)),
                const SizedBox(height: 4),
                LayoutBuilder(
                  builder: (ctx, c) => Stack(
                    children: [
                      Container(height: 3, width: c.maxWidth, decoration: BoxDecoration(color: colorScheme.outline.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(2))),
                      Container(
                        height: 3,
                        width: totalSpend == 0 || category.amount == 0 ? 0 : max(4.0, c.maxWidth * pct),
                        decoration: BoxDecoration(color: category.barColor, borderRadius: BorderRadius.circular(2)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('ETB ${_format(category.amount)}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: colorScheme.onErrorContainer)),
              Text('${(pct * 100).toStringAsFixed(0)}%', style: TextStyle(fontSize: 9, color: colorScheme.onSurfaceVariant)),
            ],
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// INSIGHT MODEL & ROW
// =============================================================================
class Insight {
  final List<InsightSpan> spans;
  final Color dotColor;
  Insight({required this.spans, required this.dotColor});
}

class _InsightRow extends StatelessWidget {
  final Insight insight;
  const _InsightRow({required this.insight});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6, height: 6,
            margin: const EdgeInsets.only(top: 4, right: 6),
            decoration: BoxDecoration(color: insight.dotColor, shape: BoxShape.circle),
          ),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant, height: 1.4),
                children: insight.spans.map((span) => TextSpan(
                  text: span.text,
                  style: span.isBold
                      ? TextStyle(fontWeight: FontWeight.w500, color: colorScheme.onSurface)
                      : TextStyle(color: colorScheme.onSurfaceVariant),
                )).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
