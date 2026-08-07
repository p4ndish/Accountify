import 'package:accountify/core/database/database.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

class TransactionMetadata {
  final int transactionId;
  final String? reason;
  final List<String> tags;

  const TransactionMetadata({
    required this.transactionId,
    required this.reason,
    required this.tags,
  });
}

class BankRepository {
  final AppDatabase _db;

  BankRepository(this._db);

  Future<List<Bank>> getBanks() async {
    return _db.select(_db.banks).get();
  }

  Future<Bank?> getBank(int id) async {
    return (_db.select(
      _db.banks,
    )..where((b) => b.id.equals(id))).getSingleOrNull();
  }

  // Bonus: Drift is reactive! You can use streams instead of futures.
  Stream<List<Bank>> watchBanks() {
    return _db.select(_db.banks).watch();
  }

  Future<List<Transaction>> getTransactions() async {
    return _db.select(_db.transactions).get();
  }

  Future<List<TransactionWithBank>> getTransactionsWithBanks() async {
    final query =
        _db.select(_db.transactions).join([
          innerJoin(_db.banks, _db.banks.id.equalsExp(_db.transactions.bank)),
        ])..orderBy([
          OrderingTerm(
            expression: _db.transactions.date,
            mode: OrderingMode.desc,
          ),
        ]);

    final rows = await query.get();
    return rows
        .map(
          (row) => TransactionWithBank(
            transaction: row.readTable(_db.transactions),
            bank: row.readTable(_db.banks),
          ),
        )
        .toList();
  }

  Future<List<TransactionWithBank>> getTransactionsWithBank(
    int bankId, {
    int limit = 100,
    int offset = 0,
  }) async {
    final query =
        _db.select(_db.transactions).join([
            innerJoin(_db.banks, _db.banks.id.equalsExp(_db.transactions.bank)),
          ])
          ..where(_db.transactions.bank.equals(bankId))
          ..orderBy([
            OrderingTerm(
              expression: _db.transactions.date,
              mode: OrderingMode.desc,
            ),
          ])
          ..limit(limit, offset: offset);

    final rows = await query.get();
    return rows
        .map(
          (row) => TransactionWithBank(
            transaction: row.readTable(_db.transactions),
            bank: row.readTable(_db.banks),
          ),
        )
        .toList();
  }

  Future<Map<String, double>> getOverallBalance() async {
    // Sum balances stored on the bank table.
    final totalBalanceResult = await (_db.selectOnly(
      _db.banks,
    )..addColumns([_db.banks.balance.sum()])).getSingle();

    // Transfers between the user's own accounts (e.g. Telebirr <-> CBE) would
    // generate both a debit on the source bank and a credit on the destination
    // bank. When such a movement can be identified it is tagged with subType
    // 'bank_in'/'bank_out' and excluded here so it is not double-counted in the
    // overall received/sent totals. Per-bank balances still account for it.
    //
    // NOTE: automatic detection of internal transfers is currently disabled.
    // The app does not store the user's own bank account numbers, so a
    // Telebirr<->bank transfer cannot be reliably distinguished from a normal
    // payment to/from another person. Those transfers are therefore counted as
    // regular sent/received. This filter is kept for any legacy rows and for
    // when explicit account-number matching is added later.
    final isInternalTransfer = _db.transactions.subType.isIn(const [
      'bank_in',
      'bank_out',
    ]);

    // Sum transactions by type, excluding internal transfers.
    final receivedResult =
        await (_db.selectOnly(_db.transactions)
              ..addColumns([_db.transactions.amount.sum()])
              ..where(
                _db.transactions.transactionType.equals('credited') &
                    isInternalTransfer.not(),
              ))
            .getSingle();

    final sentResult =
        await (_db.selectOnly(_db.transactions)
              ..addColumns([_db.transactions.amount.sum()])
              ..where(
                _db.transactions.transactionType.equals('debited') &
                    isInternalTransfer.not(),
              ))
            .getSingle();

    final totalBalance =
        totalBalanceResult.read(_db.banks.balance.sum()) ?? 0.0;
    final totalReceived =
        receivedResult.read(_db.transactions.amount.sum()) ?? 0.0;
    final totalSent = sentResult.read(_db.transactions.amount.sum()) ?? 0.0;

    return {
      'totalBalance': totalBalance,
      'totalReceived': totalReceived,
      'totalSent': totalSent,
    };
  }

  Future<void> saveTransactionMetadata({
    required int transactionId,
    required String? reason,
    required List<String> tags,
  }) async {
    final normalizedTags =
        tags
            .map((tag) => tag.trim().toLowerCase())
            .where((tag) => tag.isNotEmpty)
            .toSet()
            .toList()
          ..sort();

    await _db.transaction(() async {
      await (_db.update(
        _db.transactions,
      )..where((t) => t.id.equals(transactionId))).write(
        TransactionsCompanion(
          reason: Value(
            reason == null || reason.trim().isEmpty ? null : reason.trim(),
          ),
        ),
      );

      await (_db.delete(
        _db.transactionTags,
      )..where((row) => row.transactionId.equals(transactionId))).go();

      for (final tagName in normalizedTags) {
        final existingTag = await (_db.select(
          _db.tags,
        )..where((t) => t.name.equals(tagName))).getSingleOrNull();

        final tagId =
            existingTag?.id ??
            await _db
                .into(_db.tags)
                .insert(TagsCompanion.insert(name: tagName));

        await _db
            .into(_db.transactionTags)
            .insert(
              TransactionTagsCompanion.insert(
                transactionId: transactionId,
                tagId: tagId,
              ),
              mode: InsertMode.insertOrIgnore,
            );
      }
    });
  }

  Future<TransactionMetadata?> getTransactionMetadata(int transactionId) async {
    final transaction = await (_db.select(
      _db.transactions,
    )..where((t) => t.id.equals(transactionId))).getSingleOrNull();

    if (transaction == null) return null;

    final rows = await (_db.select(_db.transactionTags).join([
      innerJoin(_db.tags, _db.tags.id.equalsExp(_db.transactionTags.tagId)),
    ])..where(_db.transactionTags.transactionId.equals(transactionId))).get();

    final tags = rows.map((row) => row.readTable(_db.tags).name).toList()
      ..sort();

    return TransactionMetadata(
      transactionId: transaction.id,
      reason: transaction.reason,
      tags: tags,
    );
  }

  String buildAutomaticReason(Transaction transaction) {
    final isCredit = transaction.transactionType == 'credited';
    final subject = transaction.name.trim();

    if (transaction.subType == 'bank_out') {
      return 'Transfer to $subject';
    }
    if (transaction.subType == 'bank_in') {
      return 'Transfer from $subject';
    }
    if (transaction.subType == 'airtime') {
      return 'Airtime purchase';
    }
    if (transaction.subType == 'package') {
      return 'Package purchase';
    }
    if (transaction.subType == 'atm') {
      return subject.isEmpty ? 'ATM withdrawal' : subject;
    }

    return isCredit ? 'Received from $subject' : 'Payment to $subject';
  }

  Future<void> saveAutomaticReasonIfMissing(int transactionId) async {
    final transaction = await (_db.select(
      _db.transactions,
    )..where((t) => t.id.equals(transactionId))).getSingleOrNull();
    if (transaction == null) return;
    if ((transaction.reason ?? '').trim().isNotEmpty) return;

    await (_db.update(
      _db.transactions,
    )..where((t) => t.id.equals(transactionId))).write(
      TransactionsCompanion(reason: Value(buildAutomaticReason(transaction))),
    );
  }

  Future<TransactionWithBank?> getTransactionWithBankById(
    int transactionId,
  ) async {
    final query = _db.select(_db.transactions).join([
      innerJoin(_db.banks, _db.banks.id.equalsExp(_db.transactions.bank)),
    ])..where(_db.transactions.id.equals(transactionId));

    final row = await query.getSingleOrNull();
    if (row == null) return null;

    return TransactionWithBank(
      transaction: row.readTable(_db.transactions),
      bank: row.readTable(_db.banks),
    );
  }

  Future<void> updateAccountNumber(int bankId, String accountNumber) async {
    await (_db.update(_db.banks)..where((b) => b.id.equals(bankId))).write(
      BanksCompanion(accountNumber: Value(accountNumber)),
    );
  }
}

final transactionMetadataProvider =
    FutureProvider.family<TransactionMetadata?, int>((
      ref,
      transactionId,
    ) async {
      final repository = ref.watch(bankRepositoryProvider);
      return repository.getTransactionMetadata(transactionId);
    });

final bankRepositoryProvider = Provider<BankRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return BankRepository(db);
});

// -----------------------------------------------------------------------------
// 4. THE UI STATE (The Controller)
// -----------------------------------------------------------------------------
// This is what your Widget actually watches.
final banksListProvider = FutureProvider<List<Bank>>((ref) async {
  // 1. Get the repository
  final repository = ref.watch(bankRepositoryProvider);
  // 2. Return the data
  return repository.getBanks();
});

// get transactions
final transactionsListProvider = FutureProvider<List<Transaction>>((ref) async {
  final repository = ref.watch(bankRepositoryProvider);
  return repository.getTransactions();
});

final transactionsWithBanksListProvider =
    FutureProvider<List<TransactionWithBank>>((ref) async {
      final repository = ref.watch(bankRepositoryProvider);
      return repository.getTransactionsWithBanks();
    });

final transactionsWithBankListProvider = FutureProvider.autoDispose
    .family<List<TransactionWithBank>, int>((ref, bankId) async {
      ref.keepAlive();
      final repository = ref.watch(bankRepositoryProvider);
      return repository.getTransactionsWithBank(bankId);
    });

final overallBalanceProvider = FutureProvider<Map<String, double>>((ref) async {
  final repository = ref.watch(bankRepositoryProvider);
  return repository.getOverallBalance();
});
