import 'package:accountify/core/database/database.dart';
import 'package:accountify/core/providers/database_provider.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late BankRepository repository;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repository = BankRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('saves reason and multiple tags for one transaction', () async {
    final bankId = await db.into(db.banks).insert(
      BanksCompanion.insert(
        name: 'Telebirr',
        shortName: 'Telebirr',
        accountNumber: '0911223344',
        addressName: '127',
        icon: '',
      ),
    );

    final transactionId = await db.into(db.transactions).insert(
      TransactionsCompanion.insert(
        name: 'FEKERA TASEFAYE',
        bank: bankId,
        amount: 360,
        balanceAfter: 3227.27,
        transactionType: 'debited',
        paymentLink: '',
        referenceCode: 'DC14BLJ7DI',
        date: DateTime(2026, 3, 1, 19, 24, 8),
      ),
    );

    await repository.saveTransactionMetadata(
      transactionId: transactionId,
      reason: 'Dinner with friends',
      tags: ['food', 'friends'],
    );

    final metadata = await repository.getTransactionMetadata(transactionId);

    expect(metadata, isNotNull);
    expect(metadata!.reason, 'Dinner with friends');
    expect(metadata.tags, ['food', 'friends']);
  });
}
