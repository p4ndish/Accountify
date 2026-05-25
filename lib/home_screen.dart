import 'dart:ui';

import 'package:accountify/core/database/database.dart';
import 'package:accountify/core/providers/database_provider.dart';
import 'package:accountify/core/providers/message_provider.dart';
import 'package:accountify/core/providers/transaction_metadata_prompt_provider.dart';
import 'package:accountify/core/services/background_sms_service.dart';
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
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
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

  void _showAccountNumberDialog(BuildContext context, WidgetRef ref, Bank bank) {
    final controller = TextEditingController(text: bank.accountNumber);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.3),
      builder: (dialogContext) {
        return SizedBox.expand(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            insetPadding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1F2937).withValues(alpha: 0.85)
                    : Colors.white.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.06),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Bank icon + name
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: bank.icon.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: SvgPicture.asset(
                                  bank.icon,
                                  width: 24,
                                  height: 24,
                                ),
                              )
                            : Icon(Icons.account_balance, size: 20,
                                color: isDark ? Colors.white70 : Colors.grey[600]),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          bank.name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : const Color(0xFF111827),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Input field
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Account Number',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white54 : const Color(0xFF6B7280),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: controller,
                    keyboardType: TextInputType.text,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 15,
                      color: isDark ? Colors.white : const Color(0xFF111827),
                    ),
                    decoration: InputDecoration(
                      hintText: 'Enter your account number',
                      hintStyle: TextStyle(
                        color: isDark ? Colors.white30 : const Color(0xFF9CA3AF),
                      ),
                      filled: true,
                      fillColor: isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : const Color(0xFFF9FAFB),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: const Color(0xFF4F46E5).withValues(alpha: 0.5),
                          width: 1.5,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Buttons
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.of(dialogContext).pop(),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              color: isDark ? Colors.white54 : const Color(0xFF6B7280),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            final repo = ref.read(bankRepositoryProvider);
                            await repo.updateAccountNumber(
                              bank.id, controller.text.trim(),
                            );
                            if (context.mounted) {
                              ref.invalidate(banksListProvider);
                              ref.invalidate(overallBalanceProvider);
                            }
                            if (dialogContext.mounted) {
                              Navigator.of(dialogContext).pop();
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4F46E5),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Save',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          ),
        );
      },
    );
  }

  @pragma('vm:entry-point')
  static Future<void> _onActionNotificationMethod(
    ReceivedAction receivedAction,
  ) async {
    // Handle notification action (e.g., tag selection from notification)
    debugPrint('Notification action received: ${receivedAction.id}');
  }

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
        onActionReceivedMethod: _onActionNotificationMethod,
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
      // Check if SMS permission is already granted before requesting
      final smsStatus = await Permission.sms.status;
      bool granted;

      if (smsStatus.isGranted) {
        granted = true;
      } else {
        granted = await Telephony.instance.requestSmsPermissions ?? false;
      }

      if (mounted) {
        setState(() {
          _hasSmsPermission = granted;
        });
      }

      // Add delay after permission dialog to avoid lifecycle issues on Android 13+
      if (!smsStatus.isGranted) {
        await Future.delayed(const Duration(milliseconds: 300));
      }

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
    final colorScheme = Theme.of(context).colorScheme;
    final banks = ref.watch(banksListProvider);
    final overallBalance = ref.watch(overallBalanceProvider);
    final transactions = ref.watch(transactionsWithBanksListProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      
      body: Stack(
        children: [
          DefaultTabController(
            length: 2,
            child: Column(
              children: [
                // Fixed header
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
                // Fixed tab bar
                Container(
                  margin: const EdgeInsets.only(
                    left: 4,
                    right: 4,
                    top: 4,
                    bottom: 0,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: const BorderRadius.all(Radius.circular(12)),
                  ),
                  child: TabBar(
                    dividerHeight: 0,
                    indicatorPadding: const EdgeInsets.all(8),
                    indicatorColor: Colors.white,
                    labelColor: Colors.white,
                    unselectedLabelColor: colorScheme.onSurfaceVariant,
                    labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                    tabs: const [
                      Tab(text: "Banks"),
                      Tab(text: "Recent Transactions"),
                    ],
                  ),
                ),
                // Scrollable tab content
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildBanksTab(banks),
                      _buildTransactionsTab(transactions),
                    ],
                  ),
                ),
              ],
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
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: EdgeInsets.all(12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.onErrorContainer.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: colorScheme.onSurface.withValues(alpha: 0.1),
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
                      foregroundColor: colorScheme.onErrorContainer,
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
    final colorScheme = Theme.of(context).colorScheme;
    return RefreshIndicator(
      onRefresh: _handleRefresh,
      color: colorScheme.onSurface.withValues(alpha: 0.08),
      backgroundColor: colorScheme.surfaceContainerHighest,
      child: banks.when(
        loading: () => const SkeletonList(itemCount: 4, itemHeight: 100),
        error: (e, st) => Center(child: Text('Error: $e')),
        data: (banks) {
          if (banks.isEmpty) {
            return LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: SizedBox(
                    height: constraints.maxHeight,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.account_balance, size: 48, color: Colors.grey),
                          SizedBox(height: 16),
                          Text('No banks found'),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          }
          return Stack(
            children: [
              // Solid backdrop for glass effect
              Positioned.fill(
                child: Container(
                  color: colorScheme.primary.withValues(alpha: 0.06),
                ),
              ),
              ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 120),
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
                  amount: '$displayBalance ETB',
                  isGlass: true,
                  onLongPress: () => _showAccountNumberDialog(context, ref, bank),
                  onTap: () => _showBankBottomSheet(context, bank),
                ),
              );
            },
              ),
            ],
          );
        },
      ),
    );
  }

  void _showBankBottomSheet(BuildContext context, Bank bank) {
    final overlay = Overlay.of(context);
    final entry = OverlayEntry(
      builder: (context) => Material(
        color: Colors.black54,
        child: Center(
          child: CircularProgressIndicator(
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
    );
    overlay.insert(entry);

    // Remove overlay once next frame renders (bottom sheet is opening)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      entry.remove();
    });

    context.showSmoothBottomSheet(
      child: BankTransactionBottomSheet(bank: bank),
      initialChildSize: 0.6,
      minChildSize: 0.35,
      maxChildSize: 0.95,
      snap: true,
      snapSizes: const [0.35, 0.6, 0.95],
    );
  }

  Widget _buildTransactionsTab(AsyncValue<List<TransactionWithBank>> transactions) {
    final colorScheme = Theme.of(context).colorScheme;
    return RefreshIndicator(
      color: colorScheme.onSurface.withValues(alpha: 0.08),
      backgroundColor: colorScheme.surfaceContainerHighest,
      onRefresh: _handleRefresh,
      child: transactions.when(
        error: (e, st) => Center(child: Text('Error: $e')),
        loading: () => const SkeletonList(itemCount: 8),
        data: (data) {
          if (data.isEmpty) {
            return LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: SizedBox(
                    height: constraints.maxHeight,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.receipt_long, size: 48, color: Colors.grey),
                          SizedBox(height: 16),
                          Text('No transactions yet'),
                          SizedBox(height: 8),
                          Text(
                            'Pull down to refresh or check SMS permission',
                            style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          }
          return SimpleListBuilder<TransactionWithBank>(
            items: data,
            padding: const EdgeInsets.only(top: 8, bottom: 128),
            physics: const AlwaysScrollableScrollPhysics(),
            shrinkWrap: false,
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
