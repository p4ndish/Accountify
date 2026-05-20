import 'dart:math';

import 'package:accountify/core/database/database.dart';
import 'package:accountify/core/providers/database_provider.dart';
import 'package:accountify/core/theme/colors.dart';
import 'package:accountify/core/theme/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

// =============================================================================
// MONTH SUMMARY MODEL
// =============================================================================
class MonthSummary {
  final String label;
  final double totalIn;
  final double totalOut;
  final int countIn;
  final int countOut;

  const MonthSummary({
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
// INSIGHT SPAN MODEL - Makes bold/color detection explicit
// =============================================================================
class InsightSpan {
  final String text;
  final bool isBold;

  const InsightSpan(this.text, {this.isBold = false});

  TextSpan toTextSpan() => TextSpan(
    text: text,
    style: isBold ? const TextStyle(fontWeight: FontWeight.w500) : null,
  );
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

  final List<String> _periodLabels = ['3M', '6M', '1Y', 'All'];

  DateTime get _cutoff {
    final now = DateTime.now();
    switch (_periodIndex) {
      case 0: // 3M
        return now.subtract(const Duration(days: 90));
      case 1: // 6M
        return now.subtract(const Duration(days: 180));
      case 2: // 1Y
        return now.subtract(const Duration(days: 365));
      default: // All
        return DateTime(2000);
    }
  }

  /// Returns the number of calendar months in the selected period
  int get _calendarMonths {
    switch (_periodIndex) {
      case 0: // 3M
        return 3;
      case 1: // 6M
        return 6;
      case 2: // 1Y
        return 12;
      default: // All - calculate from earliest transaction
        return 1;
    }
  }

  List<TransactionWithBank> _filterTransactions(
    List<TransactionWithBank> transactions,
  ) {
    return transactions.where((t) => t.transaction.date.isAfter(_cutoff)).toList();
  }

  List<MonthSummary> _buildMonthlyData(List<TransactionWithBank> transactions) {
    final Map<String, MonthSummary> monthlyMap = {};

    for (final twb in transactions) {
      final txn = twb.transaction;
      final monthKey = DateFormat('yyyy-MM').format(txn.date);
      final monthLabel = DateFormat('MMM yy').format(txn.date);

      final existing = monthlyMap[monthKey];
      if (existing == null) {
        monthlyMap[monthKey] = MonthSummary(
          label: monthLabel,
          totalIn: txn.transactionType.toLowerCase() == 'credited' ? txn.amount : 0,
          totalOut: txn.transactionType.toLowerCase() == 'debited' ? txn.amount : 0,
          countIn: txn.transactionType.toLowerCase() == 'credited' ? 1 : 0,
          countOut: txn.transactionType.toLowerCase() == 'debited' ? 1 : 0,
        );
      } else {
        monthlyMap[monthKey] = MonthSummary(
          label: existing.label,
          totalIn: existing.totalIn + (txn.transactionType.toLowerCase() == 'credited' ? txn.amount : 0),
          totalOut: existing.totalOut + (txn.transactionType.toLowerCase() == 'debited' ? txn.amount : 0),
          countIn: existing.countIn + (txn.transactionType.toLowerCase() == 'credited' ? 1 : 0),
          countOut: existing.countOut + (txn.transactionType.toLowerCase() == 'debited' ? 1 : 0),
        );
      }
    }

    final sortedKeys = monthlyMap.keys.toList()..sort();
    return sortedKeys.map((k) => monthlyMap[k]!).toList();
  }

  List<CategoryData> _buildCategoryData(
    List<TransactionWithBank> transactions,
    bool isDark,
  ) {
    double packages = 0;
    double p2p = 0;
    double bankTransfers = 0;
    double airtime = 0;
    int packagesCount = 0;
    int p2pCount = 0;
    int bankCount = 0;
    int airtimeCount = 0;

    for (final twb in transactions) {
      final txn = twb.transaction;
      if (txn.transactionType.toLowerCase() != 'debited') continue;

      switch (txn.subType.toLowerCase()) {
        case 'package':
          packages += txn.amount;
          packagesCount++;
          break;
        case 'p2p':
          p2p += txn.amount;
          p2pCount++;
          break;
        case 'bank_out':
          bankTransfers += txn.amount;
          bankCount++;
          break;
        case 'airtime':
          airtime += txn.amount;
          airtimeCount++;
          break;
      }
    }

    final categories = [
      CategoryData(
        name: 'Packages',
        amount: packages,
        count: packagesCount,
        icon: Icons.data_usage,
        iconColor: const Color(0xFFFBBF24),
        iconBg: isDark 
            ? const Color(0x33FBBF24) 
            : const Color(0x1FFBBF24),
        barColor: const Color(0xFFFBBF24),
      ),
      CategoryData(
        name: 'P2P transfers',
        amount: p2p,
        count: p2pCount,
        icon: Icons.arrow_upward,
        iconColor: isDark ? AppColors.darkTextReceived : AppColors.textReceived,
        iconBg: isDark 
            ? AppColors.darkBgReceived 
            : AppColors.bgReceived,
        barColor: isDark ? AppColors.darkTextReceived : AppColors.textReceived,
      ),
      CategoryData(
        name: 'Bank transfers',
        amount: bankTransfers,
        count: bankCount,
        icon: Icons.account_balance,
        iconColor: const Color(0xFF60A5FA),
        iconBg: const Color(0x1A60A5FA),
        barColor: const Color(0xFF60A5FA),
      ),
      CategoryData(
        name: 'Airtime',
        amount: airtime,
        count: airtimeCount,
        icon: Icons.signal_cellular_alt,
        iconColor: const Color(0xFFA78BFA),
        iconBg: const Color(0x1AA78BFA),
        barColor: const Color(0xFFA78BFA),
      ),
    ];

    categories.sort((a, b) => b.amount.compareTo(a.amount));
    return categories.where((c) => c.amount > 0).toList();
  }

  String _formatETB(double v) => NumberFormat('#,##0', 'en_US').format(v);

  @override
  Widget build(BuildContext context) {
    final asyncTxns = ref.watch(transactionsWithBanksListProvider);
    final isDark = ref.watch(themeProvider) == AppThemeMode.dark;

    // Theme-aware colors
    final bgCard = isDark ? AppColors.darkBgCard : AppColors.bgCard;
    final border = isDark ? AppColors.darkBorderColor : AppColors.borderColor;
    final textPrim = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final textSec = isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
    final textMuted = isDark ? AppColors.darkTextMuted : AppColors.textMuted;
    final colorIn = isDark ? AppColors.darkTextReceived : AppColors.textReceived;
    final colorOut = isDark ? AppColors.darkTextSent : AppColors.textSent;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBgApp : AppColors.bgApp,
      appBar: AppBar(
        backgroundColor: bgCard,
        foregroundColor: textPrim,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(12.0),
            bottomRight: Radius.circular(12.0),
          ),
        ),
        iconTheme: IconThemeData(color: textPrim),
        titleTextStyle: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: textPrim,
        ),
        actionsIconTheme: IconThemeData(color: textPrim),
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: isDark 
                  ? AppColors.darkBgIcon 
                  : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.arrow_back_ios_new,
              size: 16,
              color: textPrim,
            ),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Analytics'),
        actions: [
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
      ),
      body: asyncTxns.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
        data: (transactions) {
          // Filter transactions once
          final filtered = _filterTransactions(transactions);
          
          // Cache aggregations to avoid re-computation on rebuilds
          final monthlyData = _buildMonthlyData(filtered);
          final categoryData = _buildCategoryData(filtered, isDark);

          // Calculate summary stats
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
          
          // Bug Fix 1: Get current balance from most recent transaction (sorted by date)
          // Bug Fix 2: Use [...filtered] to create a copy before sorting
          final latestBalance = filtered.isNotEmpty
              ? ([...filtered]..sort((a, b) => a.transaction.date.compareTo(b.transaction.date)))
                  .last.transaction.balanceAfter
              : 0.0;
          
          // Bug Fix 4: Use calendar months for avg calculation, not just months with transactions
          final numMonths = monthlyData.isEmpty ? 1 : monthlyData.length;
          final calendarMonths = _calendarMonths;
          final avgPerMonth = totalOut / (calendarMonths > 0 ? calendarMonths : 1);

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: bgCard,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: border, width: 0.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Overview',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: textPrim,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildPeriodPills(isDark, border, textSec),
                      const SizedBox(height: 12),
                      _buildSummaryGrid(
                        isDark: isDark,
                        bgCard: bgCard,
                        border: border,
                        textPrim: textPrim,
                        textMuted: textMuted,
                        colorIn: colorIn,
                        colorOut: colorOut,
                        totalIn: totalIn,
                        totalOut: totalOut,
                        currentBal: latestBalance,
                        avgPerMonth: avgPerMonth,
                        cntIn: cntIn,
                        cntOut: cntOut,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _SectionHeader(title: 'Monthly flow', textMuted: textMuted),
                const SizedBox(height: 8),
                _buildMonthlyCard(
                  isDark: isDark,
                  bgCard: bgCard,
                  border: border,
                  textMuted: textMuted,
                  colorIn: colorIn,
                  colorOut: colorOut,
                  summaries: monthlyData,
                ),
                const SizedBox(height: 16),
                _SectionHeader(title: 'Spending by category', textMuted: textMuted),
                const SizedBox(height: 8),
                _buildCategoryCard(
                  isDark: isDark,
                  bgCard: bgCard,
                  border: border,
                  textPrim: textPrim,
                  textMuted: textMuted,
                  colorOut: colorOut,
                  categories: categoryData,
                ),
                const SizedBox(height: 16),
                _SectionHeader(title: 'Net position', textMuted: textMuted),
                const SizedBox(height: 8),
                _buildNetCard(
                  isDark: isDark,
                  bgCard: bgCard,
                  border: border,
                  textMuted: textMuted,
                  colorIn: colorIn,
                  colorOut: colorOut,
                  net: totalIn - totalOut,
                  numMonths: numMonths,
                  totalTxns: cntIn + cntOut,
                ),
                const SizedBox(height: 16),
                _SectionHeader(title: 'Insights', textMuted: textMuted),
                const SizedBox(height: 8),
                _buildInsightsCard(
                  isDark: isDark,
                  bgCard: bgCard,
                  border: border,
                  textPrim: textPrim,
                  textSec: textSec,
                  textMuted: textMuted,
                  colorIn: colorIn,
                  colorOut: colorOut,
                  filtered: filtered,
                  summaries: monthlyData,
                  categories: categoryData,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ===========================================================================
  // PERIOD PILLS
  // ===========================================================================
  Widget _buildPeriodPills(bool isDark, Color border, Color textSec) {
    return Row(
      children: List.generate(_periodLabels.length, (index) {
        final isActive = _periodIndex == index;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _periodIndex = index),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              padding: const EdgeInsets.symmetric(vertical: 7),
              decoration: BoxDecoration(
                color: isActive ? AppColors.primaryBrand : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isActive ? AppColors.primaryBrand : border,
                  width: 0.5,
                ),
              ),
              child: Text(
                _periodLabels[index],
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isActive ? FontWeight.w500 : FontWeight.w400,
                  color: isActive ? Colors.white : textSec,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  // ===========================================================================
  // SUMMARY GRID
  // ===========================================================================
  Widget _buildSummaryGrid({
    required bool isDark,
    required Color bgCard,
    required Color border,
    required Color textPrim,
    required Color textMuted,
    required Color colorIn,
    required Color colorOut,
    required double totalIn,
    required double totalOut,
    required double currentBal,
    required double avgPerMonth,
    required int cntIn,
    required int cntOut,
  }) {
    return GridView.count(
      crossAxisCount: 2,
      childAspectRatio: 1.4,
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _StatCard(
          label: 'TOTAL IN',
          value: totalIn,
          sub: 'ETB · $cntIn txns',
          color: colorIn,
          bgCard: bgCard,
          border: border,
          textMuted: textMuted,
        ),
        _StatCard(
          label: 'TOTAL OUT',
          value: totalOut,
          sub: 'ETB · $cntOut txns',
          color: colorOut,
          bgCard: bgCard,
          border: border,
          textMuted: textMuted,
        ),
        _StatCard(
          label: 'CURRENT BALANCE',
          value: currentBal,
          sub: 'ETB · telebirr',
          color: AppColors.primaryBrand,
          bgCard: bgCard,
          border: border,
          textMuted: textMuted,
        ),
        _StatCard(
          label: 'AVG / MONTH',
          value: avgPerMonth,
          sub: 'ETB spent',
          color: textPrim,
          bgCard: bgCard,
          border: border,
          textMuted: textMuted,
        ),
      ],
    );
  }

  // ===========================================================================
  // MONTHLY FLOW CARD
  // ===========================================================================
  Widget _buildMonthlyCard({
    required bool isDark,
    required Color bgCard,
    required Color border,
    required Color textMuted,
    required Color colorIn,
    required Color colorOut,
    required List<MonthSummary> summaries,
  }) {
    if (summaries.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: bgCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: border, width: 0.5),
        ),
        child: Center(
          child: Text(
            'No data for selected period',
            style: TextStyle(color: textMuted),
          ),
        ),
      );
    }

    final maxVal = summaries
        .map((s) => s.totalIn > s.totalOut ? s.totalIn : s.totalOut)
        .reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Legend
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: colorIn,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 5),
              Text(
                'Money in',
                style: TextStyle(fontSize: 11, color: textMuted),
              ),
              const SizedBox(width: 12),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: colorOut,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 5),
              Text(
                'Money out',
                style: TextStyle(fontSize: 11, color: textMuted),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Bar rows
          ...summaries.asMap().entries.map((entry) {
            final month = entry.value;
            final isLast = entry.key == summaries.length - 1;
            return _MonthBarRow(
              month: month,
              maxVal: maxVal,
              textMuted: textMuted,
              colorIn: colorIn,
              colorOut: colorOut,
              border: border,
              isLast: isLast,
            );
          }),
        ],
      ),
    );
  }

  // ===========================================================================
  // CATEGORY CARD
  // ===========================================================================
  Widget _buildCategoryCard({
    required bool isDark,
    required Color bgCard,
    required Color border,
    required Color textPrim,
    required Color textMuted,
    required Color colorOut,
    required List<CategoryData> categories,
  }) {
    final totalSpend = categories.fold<double>(0, (sum, c) => sum + c.amount);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...categories.asMap().entries.map((entry) {
            final cat = entry.value;
            final isLast = entry.key == categories.length - 1;
            return Column(
              children: [
                _CategoryRow(
                  category: cat,
                  totalSpend: totalSpend,
                  textPrim: textPrim,
                  textMuted: textMuted,
                  colorOut: colorOut,
                  border: border,
                ),
                if (!isLast)
                  Divider(
                    height: 1,
                    thickness: 0.5,
                    color: border,
                  ),
              ],
            );
          }),
        ],
      ),
    );
  }

  // ===========================================================================
  // NET POSITION CARD
  // ===========================================================================
  Widget _buildNetCard({
    required bool isDark,
    required Color bgCard,
    required Color border,
    required Color textMuted,
    required Color colorIn,
    required Color colorOut,
    required double net,
    required int numMonths,
    required int totalTxns,
  }) {
    final isPositive = net >= 0;
    final bgBadge = isPositive 
        ? (isDark ? AppColors.darkBgReceived : AppColors.bgReceived)
        : (isDark ? AppColors.darkBgSent : AppColors.bgSent);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border, width: 0.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'NET POSITION',
                style: TextStyle(
                  fontSize: 10,
                  color: textMuted,
                  letterSpacing: 0.05,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${isPositive ? "+" : "-"} ETB ${_formatETB(net.abs())}',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w500,
                  color: isPositive ? colorIn : colorOut,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'over $numMonths months · $totalTxns transactions',
                style: TextStyle(
                  fontSize: 10,
                  color: textMuted,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: bgBadge,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: (isPositive ? colorIn : colorOut).withValues(alpha: 0.3),
                width: 0.5,
              ),
            ),
            child: Text(
              isPositive ? 'Inflow' : 'Outflow',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: isPositive ? colorIn : colorOut,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // INSIGHTS CARD
  // ===========================================================================
  Widget _buildInsightsCard({
    required bool isDark,
    required Color bgCard,
    required Color border,
    required Color textPrim,
    required Color textSec,
    required Color textMuted,
    required Color colorIn,
    required Color colorOut,
    required List<TransactionWithBank> filtered,
    required List<MonthSummary> summaries,
    required List<CategoryData> categories,
  }) {
    final insights = _computeInsights(
      filtered: filtered,
      summaries: summaries,
      categories: categories,
      colorIn: colorIn,
      colorOut: colorOut,
    );

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...insights.asMap().entries.map((entry) {
            final isLast = entry.key == insights.length - 1;
            return Column(
              children: [
                _InsightRow(
                  insight: entry.value,
                  textSec: textSec,
                  textPrim: textPrim,
                ),
                if (!isLast)
                  Divider(
                    height: 1,
                    thickness: 0.5,
                    color: border,
                  ),
              ],
            );
          }),
        ],
      ),
    );
  }

  List<Insight> _computeInsights({
    required List<TransactionWithBank> filtered,
    required List<MonthSummary> summaries,
    required List<CategoryData> categories,
    required Color colorIn,
    required Color colorOut,
  }) {
    final insights = <Insight>[];

    if (filtered.isEmpty || summaries.isEmpty) return insights;

    // Best in month
    final bestIn = summaries.reduce((a, b) => a.totalIn > b.totalIn ? a : b);
    if (bestIn.totalIn > 0) {
      insights.add(Insight(
        spans: [
          const InsightSpan('Best month was '),
          InsightSpan(bestIn.label, isBold: true),
          const InsightSpan(' — ETB '),
          InsightSpan(_formatETB(bestIn.totalIn), isBold: true),
          const InsightSpan(' received in '),
          InsightSpan('${bestIn.countIn}', isBold: true),
          const InsightSpan(' transactions'),
        ],
        dotColor: colorIn,
      ));
    }

    // Most out month
    final mostOut = summaries.reduce((a, b) => a.totalOut > b.totalOut ? a : b);
    if (mostOut.totalOut > 0) {
      insights.add(Insight(
        spans: [
          const InsightSpan('Highest spending was '),
          InsightSpan(mostOut.label, isBold: true),
          const InsightSpan(' — ETB '),
          InsightSpan(_formatETB(mostOut.totalOut), isBold: true),
          const InsightSpan(' across '),
          InsightSpan('${mostOut.countOut}', isBold: true),
          const InsightSpan(' transactions'),
        ],
        dotColor: colorOut,
      ));
    }

    // Top category
    if (categories.isNotEmpty) {
      final topCat = categories.first;
      final totalSpend = categories.fold<double>(0, (sum, c) => sum + c.amount);
      if (totalSpend > 0) {
        final pct = (topCat.amount / totalSpend * 100).round();
        insights.add(Insight(
          spans: [
            InsightSpan(topCat.name, isBold: true),
            const InsightSpan(' accounts for '),
            InsightSpan('$pct%', isBold: true),
            const InsightSpan(' of all spending — ETB '),
            InsightSpan(_formatETB(topCat.amount), isBold: true),
            const InsightSpan(' in '),
            InsightSpan('${topCat.count}', isBold: true),
            const InsightSpan(' purchases'),
          ],
          dotColor: const Color(0xFFFBBF24),
        ));
      }
    }

    // Largest single transaction - Bug Fix 2: Sort a copy, don't mutate original
    final sortedByAmount = [...filtered]..sort((a, b) => 
        b.transaction.amount.compareTo(a.transaction.amount));
    final largest = sortedByAmount.first;
    insights.add(Insight(
      spans: [
        const InsightSpan('Largest single transaction: ETB '),
        InsightSpan(_formatETB(largest.transaction.amount), isBold: true),
        const InsightSpan(' on '),
        InsightSpan(DateFormat('MMM d, yyyy').format(largest.transaction.date), isBold: true),
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
  final Color textMuted;

  const _SectionHeader({required this.title, required this.textMuted});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 2),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: textMuted,
          letterSpacing: 0.07,
        ),
      ),
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
  final Color bgCard;
  final Color border;
  final Color textMuted;

  const _StatCard({
    required this.label,
    required this.value,
    required this.sub,
    required this.color,
    required this.bgCard,
    required this.border,
    required this.textMuted,
  });

  String _format(double v) => NumberFormat('#,##0', 'en_US').format(v);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: textMuted,
              letterSpacing: 0.05,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'ETB ${_format(value)}',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w500,
              color: color,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 3),
          Text(
            sub,
            style: TextStyle(
              fontSize: 10,
              color: textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// MONTH BAR ROW
// =============================================================================
class _MonthBarRow extends StatelessWidget {
  final MonthSummary month;
  final double maxVal;
  final Color textMuted;
  final Color colorIn;
  final Color colorOut;
  final Color border;
  final bool isLast;

  const _MonthBarRow({
    required this.month,
    required this.maxVal,
    required this.textMuted,
    required this.colorIn,
    required this.colorOut,
    required this.border,
    required this.isLast,
  });

  String _format(double v) => NumberFormat('#,##0', 'en_US').format(v);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            month.label,
            style: TextStyle(
              fontSize: 10,
              color: textMuted,
            ),
          ),
          const SizedBox(height: 3),
          // Green bar (IN)
          _BarTrack(value: month.totalIn, maxVal: maxVal, color: colorIn, border: border),
          const SizedBox(height: 2),
          // Red bar (OUT)
          _BarTrack(value: month.totalOut, maxVal: maxVal, color: colorOut, border: border),
          const SizedBox(height: 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ETB ${_format(month.totalIn)}',
                style: TextStyle(
                  fontSize: 10,
                  color: colorIn,
                ),
              ),
              Text(
                'ETB ${_format(month.totalOut)}',
                style: TextStyle(
                  fontSize: 10,
                  color: colorOut,
                ),
              ),
            ],
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
  final Color border;

  const _BarTrack({
    required this.value,
    required this.maxVal,
    required this.color,
    required this.border,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (ctx, constraints) {
        return Stack(
          children: [
            Container(
              height: 6,
              width: constraints.maxWidth,
              decoration: BoxDecoration(
                color: border,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            Container(
              height: 6,
              width: maxVal == 0 || value == 0 
                  ? 0 
                  : max(2.0, constraints.maxWidth * (value / maxVal)),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(3),
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
  final Color textPrim;
  final Color textMuted;
  final Color colorOut;
  final Color border;

  const _CategoryRow({
    required this.category,
    required this.totalSpend,
    required this.textPrim,
    required this.textMuted,
    required this.colorOut,
    required this.border,
  });

  String _format(double v) => NumberFormat('#,##0', 'en_US').format(v);

  @override
  Widget build(BuildContext context) {
    final pct = totalSpend > 0 ? (category.amount / totalSpend) : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          // Icon box
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: category.iconBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Icon(
                category.icon,
                size: 18,
                color: category.iconColor,
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Name and progress
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category.name,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: textPrim,
                  ),
                ),
                Text(
                  '${category.count} transactions',
                  style: TextStyle(
                    fontSize: 10,
                    color: textMuted,
                  ),
                ),
                const SizedBox(height: 5),
                // Progress bar
                LayoutBuilder(
                  builder: (ctx, c) => Stack(
                    children: [
                      Container(
                        height: 3,
                        width: c.maxWidth,
                        decoration: BoxDecoration(
                          color: border,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      Container(
                        height: 3,
                        width: totalSpend == 0 || category.amount == 0 
                            ? 0 
                            : max(4.0, c.maxWidth * pct),
                        decoration: BoxDecoration(
                          color: category.barColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // Amount and percentage
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'ETB ${_format(category.amount)}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: colorOut,
                ),
              ),
              Text(
                '${(pct * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: 10,
                  color: textMuted,
                ),
              ),
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
  final Color textSec;
  final Color textPrim;

  const _InsightRow({
    required this.insight,
    required this.textSec,
    required this.textPrim,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 7,
            height: 7,
            margin: const EdgeInsets.only(top: 4, right: 7),
            decoration: BoxDecoration(
              color: insight.dotColor,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                  fontSize: 12,
                  color: textSec,
                  height: 1.4,
                ),
                children: insight.spans.map((span) => TextSpan(
                  text: span.text,
                  style: span.isBold 
                      ? TextStyle(fontWeight: FontWeight.w500, color: textPrim)
                      : TextStyle(color: textSec),
                )).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
