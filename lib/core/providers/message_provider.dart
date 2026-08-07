// Example message_provider.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:accountify/core/database/database.dart';
import 'package:accountify/core/providers/database_provider.dart';
import 'package:accountify/core/utils/banks_message_parser.dart';
import 'package:accountify/core/utils/parsed_transaction.dart';
import 'package:another_telephony/telephony.dart' hide Value;
import 'package:drift/drift.dart' hide OrderBy;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';

/// State class for SMS import status
class SmsImportState {
  final bool isLoading;
  final bool permissionGranted;
  final bool importDone;
  final int importedCount;
  final String? error;

  const SmsImportState({
    this.isLoading = false,
    this.permissionGranted = false,
    this.importDone = false,
    this.importedCount = 0,
    this.error,
  });

  SmsImportState copyWith({
    bool? isLoading,
    bool? permissionGranted,
    bool? importDone,
    int? importedCount,
    String? error,
  }) {
    return SmsImportState(
      isLoading: isLoading ?? this.isLoading,
      permissionGranted: permissionGranted ?? this.permissionGranted,
      importDone: importDone ?? this.importDone,
      importedCount: importedCount ?? this.importedCount,
      error: error ?? this.error,
    );
  }
}

/// Notifier to handle SMS import with proper state management
class SmsImportNotifier extends AsyncNotifier<SmsImportState> {
  final Telephony _telephony = Telephony.instance;
  static const _importDoneKey = 'sms_import_done_v1';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  @override
  FutureOr<SmsImportState> build() async {
    // Don't auto-check permission here - let the UI handle it
    // This prevents permission dialogs from appearing unexpectedly
    return const SmsImportState(permissionGranted: false);
  }

  /// Check if permission is granted without showing dialog
  Future<bool> checkPermissionSilently() async {
    try {
      // Try to get inbox SMS - this will fail if no permission
      await Telephony.instance.getInboxSms(
        columns: [SmsColumn.ADDRESS],
        filter: SmsFilter.where(SmsColumn.ADDRESS).equals("test"),
      );
      final newState = (state.value ?? const SmsImportState()).copyWith(
        permissionGranted: true,
      );
      state = AsyncValue.data(newState);
      return true;
    } catch (e) {
      final newState = (state.value ?? const SmsImportState()).copyWith(
        permissionGranted: false,
      );
      state = AsyncValue.data(newState);
      return false;
    }
  }

  /// Request SMS permission from user
  Future<bool> requestPermission() async {
    state = const AsyncValue.loading();
    try {
      final granted = await _telephony.requestSmsPermissions ?? false;
      final newState = SmsImportState(
        permissionGranted: granted,
        error: granted ? null : 'SMS permission was denied',
      );
      state = AsyncValue.data(newState);
      return granted;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// Import messages from SMS
  Future<int> importMessages({bool force = false}) async {
    final currentState = state.value ?? const SmsImportState();

    // Check if already imported and not forcing
    if (!force) {
      final isDone = await _isImportDone();
      if (isDone) {
        final newState = currentState.copyWith(importDone: true);
        state = AsyncValue.data(newState);
        return 0;
      }
    }

    // Check permission
    if (!currentState.permissionGranted) {
      final granted = await requestPermission();
      if (!granted) return 0;
    }

    state = AsyncValue.data(currentState.copyWith(isLoading: true));

    try {
      final newState = await _importMessagesInternal(currentState);
      state = AsyncValue.data(newState);
      return newState.importedCount;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return 0;
    }
  }

  Future<SmsImportState> _importMessagesInternal(
    SmsImportState currentState,
  ) async {
    final db = ref.read(appDatabaseProvider);
    final banks = await db.select(db.banks).get();
    final targetBanks = banks
        .where(
          (b) =>
              b.shortName == 'Telebirr' ||
              b.shortName == 'CBE' ||
              b.shortName == 'BOA',
        )
        .where((b) => b.addressName.isNotEmpty)
        .toList();

    // The user's own bank account numbers (set via the account-number dialog).
    // A Telebirr<->bank transfer whose counterparty account matches one of
    // these is a true internal movement and should be excluded from aggregate
    // received/sent totals.
    final ownedAccounts = banks
        .map((b) => b.accountNumber.trim())
        .where((a) => a.isNotEmpty)
        .toSet();

    var inserted = 0;

    for (final bank in targetBanks) {
      final messages = await _getAddressMessages(bank.addressName);
      for (final message in messages) {
        final body = message.body;
        if (body == null || body.trim().isEmpty) continue;

        final parsed = BankMessageParser(
          bank.shortName,
          body,
          timestampMillis: message.dateSent,
        ).parse();

        if (parsed == null) continue;

        final exists = await _transactionExists(
          db: db,
          bankId: bank.id,
          referenceCode: parsed.referenceCode,
        );
        if (exists) continue;

        // Detect true internal transfers: a Telebirr->bank transfer whose
        // destination account is one of the user's own accounts becomes
        // 'bank_out' so it is excluded from aggregate sent/received totals.
        var subType = parsed.subType;
        if (parsed.counterpartyAccount.isNotEmpty &&
            ownedAccounts.contains(parsed.counterpartyAccount)) {
          subType = parsed.transactionType == 'debited'
              ? 'bank_out'
              : 'bank_in';
        }

        await db.transaction(() async {
          await db
              .into(db.transactions)
              .insert(
                TransactionsCompanion.insert(
                  name: parsed.name,
                  bank: bank.id,
                  amount: parsed.amount,
                  balanceAfter: parsed.balanceAfter,
                  transactionType: parsed.transactionType,
                  paymentLink: parsed.paymentLink,
                  referenceCode: parsed.referenceCode,
                  subType: Value(subType),
                  date: parsed.date,
                ),
              );

          await _updateBankBalance(db: db, bankId: bank.id, parsed: parsed);
        });

        inserted++;
      }
    }

    await _markImportDone();

    // Invalidate providers to refresh UI
    ref.invalidate(banksListProvider);
    ref.invalidate(overallBalanceProvider);
    ref.invalidate(transactionsWithBanksListProvider);

    return currentState.copyWith(
      isLoading: false,
      importDone: true,
      importedCount: inserted,
    );
  }

  /// Force re-import of messages (for refresh)
  Future<int> refreshMessages() async {
    return await importMessages(force: true);
  }

  /// Reset import status (for testing/debugging)
  Future<void> resetImportStatus() async {
    await _storage.delete(key: _importDoneKey);
    final currentState = state.value ?? const SmsImportState();
    state = AsyncValue.data(
      currentState.copyWith(importDone: false, importedCount: 0),
    );
  }

  Future<bool> _isImportDone() async {
    final v = await _storage.read(key: _importDoneKey);
    return v == 'true';
  }

  Future<void> _markImportDone() async {
    await _storage.write(key: _importDoneKey, value: 'true');
  }

  Future<bool> _transactionExists({
    required AppDatabase db,
    required int bankId,
    required String referenceCode,
  }) async {
    final existing =
        await (db.select(db.transactions)..where(
              (t) =>
                  t.bank.equals(bankId) & t.referenceCode.equals(referenceCode),
            ))
            .getSingleOrNull();
    return existing != null;
  }

  Future<List<SmsMessage>> _getAddressMessages(String address) async {
    SmsFilter? filter;
    if (address.isNotEmpty) {
      filter = SmsFilter.where(SmsColumn.ADDRESS).equals(address);
    }
    List<SmsMessage> messages = await Telephony.instance.getInboxSms(
      columns: [SmsColumn.ADDRESS, SmsColumn.BODY, SmsColumn.DATE_SENT],
      filter: filter,
      sortOrder: [
        // Sort by DATE_SENT ASC so the last balance written is always the most recent
        OrderBy(SmsColumn.DATE_SENT, sort: Sort.ASC),
      ],
    );
    return messages;
  }

  /// Update bank balance using the balanceAfter from SMS (source of truth)
  /// This ensures accuracy even with service fees
  Future<void> _updateBankBalance({
    required AppDatabase db,
    required int bankId,
    required ParsedTransaction parsed,
  }) async {
    final current = await (db.select(
      db.banks,
    )..where((b) => b.id.equals(bankId))).getSingle();

    final newReceived = parsed.transactionType == 'credited'
        ? current.received + parsed.amount
        : current.received;
    final newSent = parsed.transactionType == 'debited'
        ? current.sent + parsed.amount
        : current.sent;

    // Use balanceAfter from SMS as the source of truth
    await (db.update(db.banks)..where((b) => b.id.equals(bankId))).write(
      BanksCompanion(
        received: Value(newReceived),
        sent: Value(newSent),
        balance: Value(parsed.balanceAfter),
      ),
    );
  }
}

/// New AsyncNotifier-based provider for SMS import
final smsImportNotifierProvider =
    AsyncNotifierProvider<SmsImportNotifier, SmsImportState>(() {
      return SmsImportNotifier();
    });

// Legacy provider for backward compatibility (deprecated)
final smsImportProvider = FutureProvider<int>((ref) async {
  final asyncState = ref.watch(smsImportNotifierProvider);
  return asyncState.when(
    data: (state) => state.importedCount,
    loading: () => 0,
    error: (_, __) => 0,
  );
});

class MessagesRepository {
  final AppDatabase _db;

  MessagesRepository(this._db);

  final Telephony _telephony = Telephony.instance;

  static const _importDoneKey = 'sms_import_done_v1';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<bool> _ensurePermissions() async {
    return await _telephony.requestSmsPermissions ?? false;
  }

  Future<bool> _isImportDone() async {
    final v = await _storage.read(key: _importDoneKey);
    return v == 'true';
  }

  Future<void> _markImportDone() async {
    await _storage.write(key: _importDoneKey, value: 'true');
  }

  Future<bool> _transactionExists({
    required int bankId,
    required String referenceCode,
  }) async {
    final existing =
        await (_db.select(_db.transactions)..where(
              (t) =>
                  t.bank.equals(bankId) & t.referenceCode.equals(referenceCode),
            ))
            .getSingleOrNull();
    return existing != null;
  }

  Future<int> importIfNeeded() async {
    if (await _isImportDone()) return 0;

    final granted = await _ensurePermissions();
    if (!granted) {
      return 0;
    }

    final banks = await _db.select(_db.banks).get();
    final targetBanks = banks
        .where(
          (b) =>
              b.shortName == 'Telebirr' ||
              b.shortName == 'CBE' ||
              b.shortName == 'BOA',
        )
        .where((b) => b.addressName.isNotEmpty)
        .toList();

    // The user's own bank account numbers, used to detect internal transfers.
    final ownedAccounts = banks
        .map((b) => b.accountNumber.trim())
        .where((a) => a.isNotEmpty)
        .toSet();

    var inserted = 0;

    for (final bank in targetBanks) {
      final messages = await getAddressMessages(bank.addressName);
      for (final message in messages) {
        final body = message.body;
        if (body == null || body.trim().isEmpty) continue;

        final parsed = BankMessageParser(
          bank.shortName,
          body,
          timestampMillis: message.dateSent,
        ).parse();
        if (parsed == null) continue;

        final exists = await _transactionExists(
          bankId: bank.id,
          referenceCode: parsed.referenceCode,
        );
        if (exists) continue;

        // Upgrade to an internal transfer when the counterparty account is one
        // of the user's own accounts, so it is excluded from aggregate totals.
        var subType = parsed.subType;
        if (parsed.counterpartyAccount.isNotEmpty &&
            ownedAccounts.contains(parsed.counterpartyAccount)) {
          subType = parsed.transactionType == 'debited'
              ? 'bank_out'
              : 'bank_in';
        }

        await _db.transaction(() async {
          await _db
              .into(_db.transactions)
              .insert(
                TransactionsCompanion.insert(
                  name: parsed.name,
                  bank: bank.id,
                  amount: parsed.amount,
                  balanceAfter: parsed.balanceAfter,
                  transactionType: parsed.transactionType,
                  paymentLink: parsed.paymentLink,
                  referenceCode: parsed.referenceCode,
                  subType: Value(subType),
                  date: parsed.date,
                ),
              );

          await _updateBankBalanceInRepo(bankId: bank.id, parsed: parsed);
        });

        inserted++;
      }
    }

    await _markImportDone();
    return inserted;
  }

  Future<List<SmsMessage>> getAddressMessages(String address) async {
    SmsFilter? filter;
    if (address.isNotEmpty) {
      filter = SmsFilter.where(SmsColumn.ADDRESS).equals(address);
    }
    List<SmsMessage> messages = await Telephony.instance.getInboxSms(
      columns: [SmsColumn.ADDRESS, SmsColumn.BODY, SmsColumn.DATE_SENT],
      filter: filter,
      sortOrder: [
        // Sort by DATE_SENT ASC so the last balance written is always the most recent
        OrderBy(SmsColumn.DATE_SENT, sort: Sort.ASC),
      ],
    );
    return messages;
  }

  /// Update bank balance using the balanceAfter from SMS (source of truth)
  Future<void> _updateBankBalanceInRepo({
    required int bankId,
    required ParsedTransaction parsed,
  }) async {
    final current = await (_db.select(
      _db.banks,
    )..where((b) => b.id.equals(bankId))).getSingle();

    final newReceived = parsed.transactionType == 'credited'
        ? current.received + parsed.amount
        : current.received;
    final newSent = parsed.transactionType == 'debited'
        ? current.sent + parsed.amount
        : current.sent;

    // Use balanceAfter from SMS as the source of truth
    await (_db.update(_db.banks)..where((b) => b.id.equals(bankId))).write(
      BanksCompanion(
        received: Value(newReceived),
        sent: Value(newSent),
        balance: Value(parsed.balanceAfter),
      ),
    );
  }

  Future<String> exportSupportedBankMessagesToJson() async {
    final granted = await _ensurePermissions();
    if (!granted) {
      throw Exception('SMS permission not granted');
    }

    final banks = await _db.select(_db.banks).get();
    final exportBanks = <Map<String, dynamic>>[];

    for (final bank in banks.where((b) => b.addressName.isNotEmpty)) {
      final messages = await getAddressMessages(bank.addressName);
      exportBanks.add({
        'id': bank.id,
        'name': bank.name,
        'shortName': bank.shortName,
        'addressName': bank.addressName,
        'messageCount': messages.length,
        'messages': messages.map((message) {
          final dateSent = message.dateSent;
          return {
            'address': message.address,
            'body': message.body,
            'dateSent': dateSent,
            'isoDate': dateSent == null
                ? null
                : DateTime.fromMillisecondsSinceEpoch(
                    dateSent,
                  ).toIso8601String(),
          };
        }).toList(),
      });
    }

    final payload = {
      'generatedAt': DateTime.now().toIso8601String(),
      'banks': exportBanks,
    };

    final directory = await getApplicationDocumentsDirectory();
    final file = File(
      '${directory.path}/supported_bank_messages_${DateTime.now().millisecondsSinceEpoch}.json',
    );

    const encoder = JsonEncoder.withIndent('  ');
    await file.writeAsString(encoder.convert(payload));

    return file.path;
  }

  /// Export ALL SMS messages organized by contact/address to Downloads folder
  /// This is useful for debugging and understanding SMS patterns
  Future<String> exportAllMessagesByContact() async {
    final granted = await _ensurePermissions();
    if (!granted) {
      throw Exception('SMS permission not granted');
    }

    // Get all SMS messages
    final allMessages = await _telephony.getInboxSms(
      columns: [
        SmsColumn.ADDRESS,
        SmsColumn.BODY,
        SmsColumn.DATE_SENT,
        SmsColumn.DATE,
      ],
    );

    // Group messages by address/contact
    final Map<String, List<Map<String, dynamic>>> messagesByContact = {};

    for (final message in allMessages) {
      final address = message.address ?? 'Unknown';
      final body = message.body ?? '';
      final dateSent = message.dateSent;

      if (!messagesByContact.containsKey(address)) {
        messagesByContact[address] = [];
      }

      messagesByContact[address]!.add({
        'body': body,
        'dateSent': dateSent,
        'dateSentIso': dateSent != null
            ? DateTime.fromMillisecondsSinceEpoch(dateSent).toIso8601String()
            : null,
        'timestamp': message.date,
        'timestampIso': message.date != null
            ? DateTime.fromMillisecondsSinceEpoch(
                message.date!,
              ).toIso8601String()
            : null,
      });
    }

    // Create export structure organized by contact
    final exportData = <Map<String, dynamic>>[];
    messagesByContact.forEach((contact, messages) {
      exportData.add({
        'contactAddress': contact,
        'messageCount': messages.length,
        'messages': messages,
      });
    });

    // Sort by contact address for consistency
    exportData.sort(
      (a, b) => (a['contactAddress'] as String).compareTo(
        b['contactAddress'] as String,
      ),
    );

    final payload = {
      'exportedAt': DateTime.now().toIso8601String(),
      'totalContacts': exportData.length,
      'totalMessages': allMessages.length,
      'contacts': exportData,
    };

    // Try to save to Downloads folder, fallback to app documents
    Directory? targetDir;
    String fileName =
        'sms_by_contact_${DateTime.now().millisecondsSinceEpoch}.json';

    // Try Downloads folder on Android
    if (Platform.isAndroid) {
      final downloadsPath = '/storage/emulated/0/Download';
      final downloadsDir = Directory(downloadsPath);
      if (downloadsDir.existsSync()) {
        targetDir = downloadsDir;
      }
    }

    // Fallback to app documents
    targetDir ??= await getApplicationDocumentsDirectory();

    final file = File('${targetDir.path}/$fileName');
    const encoder = JsonEncoder.withIndent('  ');
    await file.writeAsString(encoder.convert(payload));

    return file.path;
  }
}

final messagesRepositoryProvider = Provider<MessagesRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return MessagesRepository(db);
});
