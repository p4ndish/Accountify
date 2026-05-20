import 'package:accountify/core/database/database.dart';
import 'package:accountify/core/providers/database_provider.dart';
import 'package:accountify/core/theme/colors.dart';
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
  final String? ammount;
  final String? icon;
  final VoidCallback onTap;
  final bool? isIconTransparent;
  const CustomCardWidget({super.key, required this.title, required this.subTitle, this.ammount, this.icon, this.isIconTransparent=false, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.darkBgCard,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            // color: AppColors.darkBgCard
            // border: Border.all(color: AppColors.borderColor),
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
                      backgroundColor: isIconTransparent == true ? AppColors.darkBgIcon : AppColors.bgIcon,
                      child: (icon?.isNotEmpty ?? false) 
                          ? SvgPicture.asset(
                              icon!,
                              width: 32,
                              height: 32,
                            )
                          : Icon(Icons.person, size: 28, color: Theme.of(context).colorScheme.onSurface),
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
                            ),
                          ),
                          Text(
                            subTitle,
                            style: TextStyle(
                              fontSize: 10,
                              color: AppColors.darkTextSecondary,
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
                  if (ammount?.isNotEmpty == true ) Text(ammount!) ,

                  // button >
                  Icon(Icons.arrow_forward_ios, size: 16),
                ],
              ),
            ],
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

    return SafeArea(
      child: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              CustomHeaderWidget(
                title: widget.bank.name,
                iconPath: widget.bank.icon.isNotEmpty ? widget.bank.icon : null,
                color: AppColors.telebirrBankGradient,
                balance: Formatters.formatCurrency(widget.bank.balance.abs()),
                received: Formatters.formatCurrency(widget.bank.received),
                sent: Formatters.formatCurrency(widget.bank.sent),
              ),
              const SizedBox(height: 16),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Text(
                  'Transactions',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
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
                backgroundColor: AppColors.darkBgHover,
                child: Icon(
                  Icons.close,
                  size: 20,
                  color: AppColors.darkTextPrimary,
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
    return Material(
      color: AppColors.darkBgCard,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: AppColors.darkBgHover,
            // border: Border.all(color: AppColors.borderColor),
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
                          ? AppColors.darkBgSent
                          : AppColors.darkBgReceived,
                      child: SvgPicture.asset(
                        isDebit
                            ? AppAssets.arrowDownwardIcon
                            : AppAssets.arrowUpwardIcon,
                        colorFilter: ColorFilter.mode(
                          isDebit ? AppColors.darkTextSent : AppColors.darkTextReceived,
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
                            ),
                          ),
                          Text(
                            '• $date',
                            style: TextStyle(
                              fontSize: 10,
                              color: AppColors.darkTextSecondary,
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
                      color: isDebit
                          ? AppColors.darkTextSent
                          : AppColors.darkTextReceived,
                    ),
                  ),

                  // button >
                  Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.darkTextSecondary),
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
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Material(
          color: AppColors.darkBgCard,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {},
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.darkBgHover,
                    AppColors.darkBgHover.withOpacity(0.5),
                    AppColors.darkBgHover,
                  ],
                  stops: [
                    (_animation.value - 0.3).clamp(0.0, 1.0),
                    _animation.value.clamp(0.0, 1.0),
                    (_animation.value + 0.3).clamp(0.0, 1.0),
                  ],
                ),
                // border: Border.all(color: AppColors.borderColor),
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
                          backgroundColor: AppColors.darkBgSheet.withOpacity(0.3),
                          child: null
                        ),

                        // bank or wallet name with number
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
                                  color: AppColors.darkBgSheet.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              SizedBox(height: 4),
                              Container(
                                height: 10,
                                width: 80,
                                decoration: BoxDecoration(
                                  color: AppColors.darkBgSheet.withOpacity(0.2),
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
                          color: AppColors.darkBgSheet.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
