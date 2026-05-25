// lib/core/database/database.dart

import 'package:accountify/core/constants/banks_list.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'dart:io';

part 'database.g.dart';  // Will be generated

// Define your tables
class Banks extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get shortName => text()();
  TextColumn get accountNumber => text()();
  TextColumn get addressName => text()();
  TextColumn get icon => text()();
  // will be used to calculate balance and also total balance
  RealColumn get balance => real().withDefault(const Constant(0.0))();
  RealColumn get received => real().withDefault(const Constant(0.0))();
  RealColumn get sent => real().withDefault(const Constant(0.0))();


  
  
}

class Tags extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().unique()();
}

class TransactionTags extends Table {
  IntColumn get transactionId => integer().references(Transactions, #id)();
  IntColumn get tagId => integer().references(Tags, #id)();

  @override
  Set<Column<Object>>? get primaryKey => {transactionId, tagId};
}

class Transactions extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  IntColumn get bank => integer().references(Banks, #id)();
  RealColumn get amount => real()();
  RealColumn get balanceAfter => real()();
  TextColumn get transactionType => text()(); // 'credited' | 'debited'
  TextColumn get paymentLink => text()();
  TextColumn get referenceCode => text()();
  
  // Additional fields for transaction details
  TextColumn get secondaryReferenceCode => text().withDefault(const Constant(''))(); // bank ref for wallet→bank
  RealColumn get fee => real().withDefault(const Constant(0.0))();
  RealColumn get feeVat => real().withDefault(const Constant(0.0))();
  TextColumn get subType => text().withDefault(const Constant(''))(); // 'p2p' | 'bank_in' | 'bank_out' | 'package' | 'airtime'

  DateTimeColumn get date => dateTime()();
  TextColumn get tag => text().nullable()();
  TextColumn get reason => text().nullable()();
}

const List<String> defaultTransactionTags = [
  'bills',
  'transfer',
  'utility',
  'bank',
];


@DriftDatabase(tables: [Banks, Transactions, Tags, TransactionTags])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());
  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 5;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          // Create composite index for new installations
          await customStatement(
            'CREATE INDEX IF NOT EXISTS transactions_bank_date_index ON transactions(bank, date DESC)',
          );
        },
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.addColumn(transactions, transactions.balanceAfter);
          }
          if (from < 3) {
            await m.addColumn(transactions, transactions.secondaryReferenceCode);
            await m.addColumn(transactions, transactions.fee);
            await m.addColumn(transactions, transactions.feeVat);
            await m.addColumn(transactions, transactions.subType);
          }
          if (from < 4) {
            await m.addColumn(transactions, transactions.reason);
            await m.createTable(tags);
            await m.createTable(transactionTags);
          }
          if (from < 5) {
            // Add composite index for faster bank+date queries
            await customStatement(
              'CREATE INDEX IF NOT EXISTS transactions_bank_date_index ON transactions(bank, date DESC)',
            );
          }
        },
      );

  Future<void> init() async {
    // Ensure database is created and ready
    
    
    // Insert supported banks from Constants
    for (var bank in Constants.supportedBanks) {
      final shortName = bank['shortName']!;
      final icon = bank['icon'] ?? '';
      final accountNumber = bank['accountNumber']!;
      final addressName = bank['addressName']!;

      final existing = await (select(banks)
            ..where((b) => b.shortName.equals(shortName)))
          .getSingleOrNull();

      if (existing == null) {
        await into(banks).insert(
          BanksCompanion.insert(
            name: bank['name']!,
            shortName: shortName,
            accountNumber: accountNumber,
            addressName: addressName,
            icon: icon,
          ),
        );
      } else {
        await (update(banks)..where((b) => b.id.equals(existing.id))).write(
          BanksCompanion(
            name: Value(bank['name']!),
            shortName: Value(shortName),
            addressName: Value(addressName),
            icon: Value(icon),
          ),
        );
      }
    }

    // Insert historical transactions 
    for (var bank in Constants.supportedBanks) {
      final shortName = bank['shortName']!;
      final icon = bank['icon'] ?? '';
      final accountNumber = bank['accountNumber']!;
      final addressName = bank['addressName']!;

      // final messages = await getAddressMessages(shortName);


      
    }
    
  }
}

// Data class for joined query results
class TransactionWithBank {
  final Transaction transaction;
  final Bank bank;
  TransactionWithBank({
    required this.transaction,
    required this.bank,
  });
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    // Create the database in the documents directory
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'accountify.db'));

    // Create the database and run PRAGMA statements
    return NativeDatabase(
      file,
      setup: (rawDb) {
        rawDb.execute('PRAGMA foreign_keys = ON');
      },
    );
  });
}
