import 'dart:async';

import 'package:accountify/core/database/database.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:accountify/core/utils/banks_message_parser.dart';
import 'package:accountify/core/utils/parsed_transaction.dart';
import 'package:another_telephony/telephony.dart' hide Value;
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:drift/drift.dart' hide JsonKey;
import 'package:flutter/material.dart';

/// Foreground SMS listener plus notification bridge for transaction metadata prompts.
class BackgroundSmsService {
  static final BackgroundSmsService _instance = BackgroundSmsService._internal();
  factory BackgroundSmsService() => _instance;
  BackgroundSmsService._internal();

  static void Function(int transactionId)? onTransactionCaptured;

  static const List<String> predefinedMetadataTags = [
    'food',
    'transfer',
    'bills',
    'utility',
    'shopping',
  ];

  static const String metadataPromptActionKey = 'OPEN_METADATA_PROMPT';
  static const String metadataPromptTransactionIdKey = 'transaction_id';
  static const String metadataPromptRequestedKey = 'metadata_prompt_requested';

  static List<String> get promptTags => predefinedMetadataTags;

  static int? extractPromptTransactionId(ReceivedAction action) {
    final payload = action.payload;
    if (payload == null) return null;
    if (payload[metadataPromptRequestedKey] != 'true') return null;
    return int.tryParse(payload[metadataPromptTransactionIdKey] ?? '');
  }

  static bool isMetadataPromptAction(ReceivedAction action) {
    return action.buttonKeyPressed == metadataPromptActionKey;
  }

  final Telephony _telephony = Telephony.instance;
  bool _isInitialized = false;
  int? _lastCapturedTransactionId;
  StreamSubscription<SmsMessage>? _smsSubscription;

  int? consumePendingPromptTransactionId() {
    final value = _lastCapturedTransactionId;
    _lastCapturedTransactionId = null;
    return value;
  }

  void markPromptRequested(int transactionId) {
    _lastCapturedTransactionId = transactionId;
    onTransactionCaptured?.call(transactionId);
  }

  Future<void> initialize() async {
    if (_isInitialized) return;

    await AwesomeNotifications().initialize(
      null,
      [
        NotificationChannel(
          channelKey: 'transaction_channel',
          channelName: 'Transaction Notifications',
          channelDescription: 'Notifications for new bank transactions',
          defaultColor: const Color(0xFF9D50DD),
          ledColor: Colors.white,
          importance: NotificationImportance.High,
          channelShowBadge: true,
          defaultRingtoneType: DefaultRingtoneType.Notification,
          playSound: true,
          enableVibration: true,
        ),
      ],
      debug: false,
    );

    _isInitialized = true;
  }

  Future<bool> requestNotificationPermission() async {
    try {
      final isAllowed = await AwesomeNotifications().isNotificationAllowed();
      if (!isAllowed) {
        return await AwesomeNotifications().requestPermissionToSendNotifications();
      }
      return true;
    } catch (e) {
      debugPrint('Error requesting notification permission: $e');
      return false;
    }
  }

  Future<void> startListening() async {
    final hasPermission = await _telephony.requestSmsPermissions ?? false;
    if (!hasPermission) {
      debugPrint('SMS permission not granted');
      return;
    }

    _telephony.listenIncomingSms(
      onNewMessage: (SmsMessage message) async {
        await _processIncomingSms(message);
      },
      listenInBackground: false,
    );

    debugPrint('SMS listening started (foreground)');
  }

  Future<void> _processIncomingSms(SmsMessage message) async {
    final address = message.address ?? '';
    final body = message.body ?? '';

    final bankShortName = _getBankShortName(address);
    if (bankShortName == null) return;

    final parsed = BankMessageParser(
      bankShortName,
      body,
      timestampMillis: message.dateSent ?? DateTime.now().millisecondsSinceEpoch,
    ).parse();

    if (parsed == null) return;

    final url = _extractUrl(body);
    final transactionId = await _saveTransaction(
      bankShortName: bankShortName,
      parsed: parsed,
      url: url,
      address: address,
    );

    if (transactionId == null) return;

    markPromptRequested(transactionId);

    // Show system overlay if permission granted
    await _showSystemOverlay(
      bankShortName: bankShortName,
      parsed: parsed,
    );

    await _showTransactionNotification(
      bankShortName: bankShortName,
      parsed: parsed,
      url: url,
      transactionId: transactionId,
    );
  }

  String? _getBankShortName(String address) {
    final upperAddress = address.toUpperCase();

    if (address == '127') return 'Telebirr';
    if (upperAddress == 'CBE') return 'CBE';
    if (upperAddress == 'BOA') return 'BOA';
    if (upperAddress.contains('AWASH')) return 'AWASH';
    if (upperAddress.contains('DASHEN')) return 'DASHEN';

    return null;
  }

  String? _extractUrl(String body) {
    final urlRegex = RegExp(
      r'https?://[^\s<>"{}|\\^`\[\]]+',
      caseSensitive: false,
    );
    final match = urlRegex.firstMatch(body);
    return match?.group(0);
  }

  Future<void> _showSystemOverlay({
    required String bankShortName,
    required ParsedTransaction parsed,
  }) async {
    try {
      final hasPermission = await FlutterOverlayWindow.isPermissionGranted();
      if (!hasPermission) return;

      final isActive = await FlutterOverlayWindow.isActive();
      if (isActive) {
        await FlutterOverlayWindow.closeOverlay();
      }

      await FlutterOverlayWindow.showOverlay(
        enableDrag: true,
        height: 120,
        width: WindowSize.matchParent,
        alignment: OverlayAlignment.topCenter,
        positionGravity: PositionGravity.auto,
      );

      await Future.delayed(const Duration(milliseconds: 300));

      await FlutterOverlayWindow.shareData({
        'bankName': bankShortName,
        'amount': parsed.amount,
        'isCredit': parsed.transactionType == 'credited',
        'description': parsed.name,
      });
    } catch (e) {
      debugPrint('Failed to show system overlay: $e');
    }
  }

  Future<int?> _saveTransaction({
    required String bankShortName,
    required ParsedTransaction parsed,
    required String? url,
    required String address,
  }) async {
    try {
      final db = AppDatabase();

      final bank = await (db.select(db.banks)
            ..where((b) => b.shortName.equals(bankShortName)))
          .getSingleOrNull();

      if (bank == null) {
        await db.close();
        return null;
      }

      final existing = await (db.select(db.transactions)
            ..where((t) => t.referenceCode.equals(parsed.referenceCode)))
          .getSingleOrNull();

      if (existing != null) {
        await db.close();
        return existing.id;
      }

      final transactionId = await db.into(db.transactions).insert(
            TransactionsCompanion.insert(
              name: parsed.name,
              bank: bank.id,
              amount: parsed.amount,
              balanceAfter: parsed.balanceAfter,
              transactionType: parsed.transactionType,
              paymentLink: url ?? '',
              referenceCode: parsed.referenceCode,
              date: parsed.date,
            ),
          );

      final newReceived = parsed.transactionType == 'credited'
          ? bank.received + parsed.amount
          : bank.received;
      final newSent = parsed.transactionType == 'debited'
          ? bank.sent + parsed.amount
          : bank.sent;

      await (db.update(db.banks)..where((b) => b.id.equals(bank.id))).write(
        BanksCompanion(
          received: Value(newReceived),
          sent: Value(newSent),
          balance: Value(parsed.balanceAfter),
        ),
      );

      await db.close();
      return transactionId;
    } catch (e) {
      debugPrint('Error saving transaction: $e');
      return null;
    }
  }

  Future<void> _showTransactionNotification({
    required String bankShortName,
    required ParsedTransaction parsed,
    required String? url,
    required int transactionId,
  }) async {
    final isCredit = parsed.transactionType == 'credited';
    final actionType = isCredit ? 'Received' : 'Sent';

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        channelKey: 'transaction_channel',
        title: '$actionType - $bankShortName',
        body: '${isCredit ? '+' : '-'}${parsed.amount.toStringAsFixed(2)} ETB\n${parsed.name}',
        payload: {
          'transaction_ref': parsed.referenceCode,
          'bank': bankShortName,
          'amount': parsed.amount.toString(),
          'type': parsed.transactionType,
          'url': url ?? '',
          metadataPromptTransactionIdKey: '$transactionId',
          metadataPromptRequestedKey: 'true',
        },
        notificationLayout: NotificationLayout.Default,
        category: NotificationCategory.Message,
        wakeUpScreen: false,
        fullScreenIntent: false,
        criticalAlert: false,
      ),
      actionButtons: [
        NotificationActionButton(
          key: metadataPromptActionKey,
          label: 'Add details',
        ),
        NotificationActionButton(
          key: 'TAG_UTILITY',
          label: 'Utility',
        ),
        NotificationActionButton(
          key: 'TAG_TRANSFER',
          label: 'Transfer',
        ),
        NotificationActionButton(
          key: 'TAG_BILLS',
          label: 'Bills',
        ),
        NotificationActionButton(
          key: 'TAG_FOOD',
          label: 'Food',
        ),
      ],
    );
  }

  static Future<void> handleNotificationAction(ReceivedAction receivedAction) async {
    if (isMetadataPromptAction(receivedAction)) {
      final transactionId = extractPromptTransactionId(receivedAction);
      if (transactionId != null) {
        BackgroundSmsService().markPromptRequested(transactionId);
      }
      return;
    }

    final payload = receivedAction.payload;
    if (payload == null) return;

    final transactionRef = payload['transaction_ref'];
    final tagKey = receivedAction.buttonKeyPressed;
    if (transactionRef == null || tagKey == null) return;

    String? tagName;
    switch (tagKey) {
      case 'TAG_UTILITY':
        tagName = 'utility';
        break;
      case 'TAG_TRANSFER':
        tagName = 'transfer';
        break;
      case 'TAG_BILLS':
        tagName = 'bills';
        break;
      case 'TAG_FOOD':
        tagName = 'food';
        break;
    }

    if (tagName == null) return;

    try {
      final db = AppDatabase();
      final transaction = await (db.select(db.transactions)
            ..where((t) => t.referenceCode.equals(transactionRef)))
          .getSingleOrNull();

      if (transaction != null) {
        await (db.update(db.transactions)
              ..where((t) => t.id.equals(transaction.id)))
            .write(TransactionsCompanion(tag: Value(tagName)));
      }

      await db.close();

      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
          channelKey: 'transaction_channel',
          title: 'Tag Added',
          body: 'Transaction tagged as $tagName',
          notificationLayout: NotificationLayout.Default,
        ),
      );
    } catch (e) {
      debugPrint('Error adding tag: $e');
    }
  }

  void stopListening() {
    _smsSubscription?.cancel();
    _isInitialized = false;
  }
}
