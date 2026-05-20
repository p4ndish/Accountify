import 'package:accountify/core/database/database.dart';
import 'package:accountify/core/providers/database_provider.dart';
import 'package:accountify/core/providers/message_provider.dart';
import 'package:accountify/core/providers/transaction_metadata_prompt_provider.dart';
import 'package:accountify/core/services/background_sms_service.dart';
import 'package:accountify/core/theme/colors.dart';
import 'package:accountify/core/utils/formatters.dart';
import 'package:accountify/core/widgets/custom_cards_widget.dart';
import 'package:accountify/core/widgets/header_wdiget.dart';
import 'package:accountify/core/widgets/loading/loading_overlay.dart';
import 'package:accountify/core/widgets/transaction_metadata_bottom_sheet.dart';
import 'package:accountify/core/widgets/transaction_overlay.dart';
import 'package:accountify/core/widgets/transitions/animated_list_builder.dart';
import 'package:accountify/core/widgets/transitions/modal_transitions.dart';
import 'package:accountify/core/widgets/transitions/page_transitions.dart';
import 'package:accountify/features/banks/screens/transaction_detail_screen.dart';
import 'package:accountify/notification_handler.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:another_telephony/telephony.dart' hide Value;
import 'package:permission_handler/permission_handler.dart';

// Note: Background SMS service simplified to foreground-only mode
// to avoid Android foreground service timing restrictions

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with WidgetsBindingObserver {
  bool? _hasSmsPermission;
  bool _bannerDismissed = false;
  bool _isShowingMetadataPrompt = false;

  List<String> get _metadataPromptTags => BackgroundSmsService.promptTags;

  Future<void> _scheduleMetadataPromptPresentation() async {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Future.microtask(_tryPresentMetadataPrompt);
    });
  }

  Future<void> _tryPresentMetadataPrompt() async {
    if (!mounted || _isShowingMetadataPrompt) return;
    if (WidgetsBinding.instance.lifecycleState != AppLifecycleState.resumed) return;
    final route = ModalRoute.of(context);
    if (route != null && !route.isCurrent) return;

    final promptState = ref.read(transactionMetadataPromptProvider);
    final transactionId = promptState.activeTransactionId;
    if (transactionId == null) return;

    final repository = ref.read(bankRepositoryProvider);
    final transaction = await repository.getTransactionWithBankById(transactionId);
    if (transaction == null) {
      ref.read(transactionMetadataPromptProvider.notifier).completeActivePrompt();
      await _scheduleMetadataPromptPresentation();
      return;
    }

    final metadata = await repository.getTransactionMetadata(transactionId);
    final alreadyFilled = metadata != null &&
        ((metadata.reason?.trim().isNotEmpty ?? false) || metadata.tags.isNotEmpty);
    if (alreadyFilled) {
      ref.read(transactionMetadataPromptProvider.notifier).completeActivePrompt();
      await _scheduleMetadataPromptPresentation();
      return;
    }

    if (!mounted) return;

    setState(() {
      _isShowingMetadataPrompt = true;
    });

    await Future<void>.delayed(Duration.zero);
    if (!mounted) return;

    await context.showSmoothBottomSheet(
      child: TransactionMetadataBottomSheet(
        transactionId: transaction.transaction.id,
        title: transaction.transaction.name,
        subtitle:
            '${transaction.transaction.transactionType == 'debited' ? '-' : '+'}ETB ${transaction.transaction.amount.toStringAsFixed(2)}',
        predefinedTags: _metadataPromptTags,
      ),
      initialChildSize: 0.65,
      minChildSize: 0.65,
      maxChildSize: 0.9,
    );

    if (!mounted) return;

    ref.invalidate(transactionsWithBanksListProvider);
    ref.read(transactionMetadataPromptProvider.notifier).completeActivePrompt();

    setState(() {
      _isShowingMetadataPrompt = false;
    });

    await _scheduleMetadataPromptPresentation();
  }

  void _listenForPromptState() {
    ref.listenManual<TransactionMetadataPromptState>(
      transactionMetadataPromptProvider,
      (_, next) {
        if (next.activeTransactionId != null) {
          _scheduleMetadataPromptPresentation();
        }
      },
    );
  }

  Future<void> _queuePromptTransaction(int transactionId) async {
    // Show overlay immediately for visual feedback
    await _showTransactionOverlay(transactionId);
    
    ref.read(transactionMetadataPromptProvider.notifier).enqueue(transactionId);
    Future.microtask(_tryPresentMetadataPrompt);
  }

  Future<void> _showTransactionOverlay(int transactionId) async {
    if (!mounted) return;
    
    final repository = ref.read(bankRepositoryProvider);
    final transactionWithBank = await repository.getTransactionWithBankById(transactionId);
    if (transactionWithBank == null || !mounted) return;
    
    final transaction = transactionWithBank.transaction;
    final bank = transactionWithBank.bank;
    final isCredit = transaction.transactionType == 'credited';
    
    TransactionOverlayController.show(
      context: context,
      bankName: bank.shortName,
      amount: transaction.amount,
      isCredit: isCredit,
      senderOrRecipient: transaction.name,
      onTap: () {
        // Navigate to transaction detail when tapped
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => TransactionDetailScreen(transaction: transaction),
          ),
        );
      },
    );
  }

  void _consumeDeferredPrompt() {
    final transactionId = BackgroundSmsService().consumePendingPromptTransactionId();
    if (transactionId == null) return;
    _queuePromptTransaction(transactionId);
  }

  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _listenForPromptState();

    BackgroundSmsService.onTransactionCaptured = (transactionId) {
      if (!mounted) return;
      _queuePromptTransaction(transactionId);
    };

    // Wait for first frame to be rendered before doing any heavy initialization
    // This avoids lifecycle conflicts during the initial app startup
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Add significant delay to let the app fully settle
      await Future.delayed(const Duration(seconds: 1));
      await _checkPermission();

      // Additional delay after permission dialog
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        await _initializeServices();
        _consumeDeferredPrompt();
        _tryPresentMetadataPrompt();
      }
    });
  }

  @override
  void dispose() {
    BackgroundSmsService.onTransactionCaptured = null;
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (_hasSmsPermission == null) {
        _checkPermission();
      }
      _consumeDeferredPrompt();
      _tryPresentMetadataPrompt();
    }
  }

  Future<void> _initializeServices() async {
    // Initialize SMS service (foreground only)
    try {
      final bgService = BackgroundSmsService();
      await bgService.initialize();
      await bgService.startListening();
    } catch (e) {
      debugPrint('Failed to initialize SMS service: $e');
    }

    // Skip notification setup in debug mode if it's causing crashes
    // This can be enabled in release mode or once the issue is resolved
    const bool skipNotificationsInDebug = false; // Set to true if crashes persist

    if (skipNotificationsInDebug) {
      debugPrint('Skipping notification setup in debug mode');
      return;
    }

    // Delay notification setup significantly to avoid lifecycle conflicts
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;

    try {
      // Listen for notification actions (tag selection)
      await AwesomeNotifications().setListeners(
        onActionReceivedMethod: onActionNotificationMethod,
      );
    } catch (e) {
      debugPrint('Failed to set notification listeners: $e');
    }

    // Request notification permission separately
    try {
      final bgService = BackgroundSmsService();
      await bgService.requestNotificationPermission();
    } catch (e) {
      debugPrint('Failed to request notification permission: $e');
    }
  }



  Future<void> _checkPermission() async {
    if (_hasSmsPermission != null) return;
    setState(() => _hasSmsPermission = false);
    try {
      final telephony = Telephony.instance;
      final granted = await telephony.requestSmsPermissions ?? false;
      
      if (mounted) {
        setState(() {
          _hasSmsPermission = granted;
        });
      }
      
      // Add delay after permission dialog to avoid lifecycle issues on Android 13+
      await Future.delayed(const Duration(milliseconds: 300));
      
      if (granted && mounted) {
        try {
          await ref.read(smsImportNotifierProvider.notifier).importMessages();
        } catch (e) {
          debugPrint('Failed to import messages: $e');
        }
      }
    } catch (e) {
      debugPrint('Error checking SMS permission: $e');
    }
  }

  Future<void> _requestPermission() async {
    final telephony = Telephony.instance;
    final granted = await telephony.requestSmsPermissions ?? false;
    
    if (mounted) {
      setState(() {
        _hasSmsPermission = granted;
      });
    }
    
    if (granted) {
      await ref.read(smsImportNotifierProvider.notifier).importMessages();
    }
  }

  Future<void> _openAppSettings() async {
    await openAppSettings();
  }

  Future<void> _handleRefresh() async {
    await ref.read(smsImportNotifierProvider.notifier).refreshMessages();
    ref.invalidate(banksListProvider);
    ref.invalidate(overallBalanceProvider);
    ref.invalidate(transactionsWithBanksListProvider);
  }

  @override
  Widget build(BuildContext context) {
    final banks = ref.watch(banksListProvider);
    final overallBalance = ref.watch(overallBalanceProvider);
    final transactions = ref.watch(transactionsWithBanksListProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      floatingActionButton: kDebugMode
          ? FloatingActionButton(
              onPressed: () async {
                // final repo = ref.read(messagesRepositoryProvider);
                // final path = await repo.exportAllMessagesByContact();
                // print('Exported to: $path');

                debugPrint('Tapped transaction: ${transactions.value?.first.transaction.name}');
                Navigator.of(context, rootNavigator: true).push(
                  MaterialPageRoute(
                    builder: (context) => Scaffold(
                      appBar: AppBar(title: Text('TEST')),
                      body: Center(child: Text('Transaction: ${transactions.value?.first.transaction.name}')),
                    ),
                  ),
                );
                
              },
              child: const Icon(Icons.sms),
            )
          : null,
      body: Stack(
        children: [
          DefaultTabController(
            length: 2,
            child: NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) => [
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      overallBalance.when(
                        loading: () => CustomHeaderWidget(
                          title: "My Banks",
                          balance: "Loading...",
                          received: "...",
                          sent: "...",
                        ),
                        error: (e, st) => CustomHeaderWidget(
                          title: "My Banks",
                          balance: "Error",
                          received: "0.0",
                          sent: "0.0",
                        ),
                        data: (data) {
                          final balance = data["totalBalance"] ?? 0.0;
                          final received = data["totalReceived"] ?? 0.0;
                          final sent = data["totalSent"] ?? 0.0;
                          
                          return CustomHeaderWidget(
                            title: "My Banks",
                            balance: Formatters.formatCurrency(balance.abs()),
                            received: Formatters.formatCurrency(received),
                            sent: Formatters.formatCurrency(sent),
                          );
                        },
                      ),
                      Container(
                        margin: const EdgeInsets.only(
                          left: 4,
                          right: 4,
                          top: 4,
                          bottom: 0,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.darkBgCard,
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                        ),
                        child: TabBar(
                          dividerHeight: 0,
                          indicatorPadding: EdgeInsets.all(8),
                          indicatorColor: AppColors.darkBgSheet,
                          tabs: [
                            Tab(text: "Banks"),
                            Tab(text: "Recent Transactions"),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              body: TabBarView(
                children: [
                  _buildBanksTab(banks),
                  _buildTransactionsTab(transactions),
                ],
              ),
            ),
          ),
          // SMS Permission Banner - Only show when permission is NOT granted
          if (_hasSmsPermission == false && !_bannerDismissed)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildPermissionBanner(),
            ),
        ],
      ),
    );
  }

  Widget _buildPermissionBanner() {
    return Container(
      margin: EdgeInsets.all(12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade900.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.sms_failed, color: Colors.white),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'SMS Permission Required',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _bannerDismissed = true;
                    });
                  },
                  child: Icon(Icons.close, color: Colors.white70, size: 20),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              'Allow access to SMS to automatically import bank transactions.',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 13,
              ),
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _requestPermission,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.orange.shade900,
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text('Allow'),
                  ),
                ),
                SizedBox(width: 12),
                TextButton(
                  onPressed: _openAppSettings,
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white70,
                  ),
                  child: Text('Settings'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBanksTab(AsyncValue<List<Bank>> banks) {
    return RefreshIndicator(
      onRefresh: _handleRefresh,
      color: AppColors.darkBgIcon,
      backgroundColor: AppColors.bgCard,
      child: banks.when(
        loading: () => const SkeletonList(itemCount: 4, itemHeight: 100),
        error: (e, st) => Center(child: Text('Error: $e')),
        data: (banks) {
          if (banks.isEmpty) {
            return ListView(
              children: [
                SizedBox(height: 100),
                Center(
                  child: Column(
                    children: [
                      Icon(Icons.account_balance, size: 48, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No banks found'),
                    ],
                  ),
                ),
              ],
            );
          }
          return ListView.builder(
            physics: AlwaysScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: banks.length,
            itemBuilder: (context, index) {
              final bank = banks[index];
              // Show absolute balance formatted with commas
              final displayBalance = Formatters.formatCurrency(bank.balance.abs());
              
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                child: CustomCardWidget(
                  title: bank.name,
                  subTitle: bank.accountNumber,
                  icon: bank.icon,
                  ammount: '$displayBalance ETB',
                  onTap: () async {
                    final loader = LoadingController();
                    loader.show(message: 'Opening ${bank.name}...');
                    await Future.delayed(const Duration(milliseconds: 150));
                    if (!context.mounted) {
                      loader.hide();
                      return;
                    }
                    loader.hide();
                    await context.showSmoothBottomSheet(
                      child: BankTransactionBottomSheet(bank: bank),
                      initialChildSize: 0.5,
                      minChildSize: 0.5,
                      maxChildSize: 0.95,
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildTransactionsTab(AsyncValue<List<TransactionWithBank>> transactions) {
    return RefreshIndicator(
      color: AppColors.darkBgIcon,
      backgroundColor: AppColors.bgCard,
      onRefresh: _handleRefresh,
      child: transactions.when(
        error: (e, st) => Center(child: Text('Error: $e')),
        loading: () => const SkeletonList(itemCount: 8),
        data: (data) {
          if (data.isEmpty) {
            return ListView(
              children: [
                SizedBox(height: 100),
                Center(
                  child: Column(
                    children: [
                      Icon(Icons.receipt_long, size: 48, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No transactions yet'),
                      SizedBox(height: 8),
                      Text(
                        'Pull down to refresh or check SMS permission',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.darkTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }
          return SimpleListBuilder<TransactionWithBank>(
            items: data,
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemBuilder: (context, row, index) {
              final isDebit = row.transaction.transactionType.toLowerCase() == 'debited';
              final formattedAmount = Formatters.formatCurrency(row.transaction.amount);
              final formattedDate = Formatters.formatDateTime(row.transaction.date);
              
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                child: CustomTransactionCardWidget(
                  isDebit: isDebit,
                  amount: row.transaction.amount,
                  formattedAmount: '${isDebit ? "-" : "+"}$formattedAmount Br',
                  date: formattedDate,
                  bank: row.bank.name,
                  onTap: () {
                    debugPrint('Transaction tapped: ${row.transaction.name}, amount: ${row.transaction.amount}');
                    context.pushScale(
                      TransactionDetailScreen(transaction: row.transaction),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
