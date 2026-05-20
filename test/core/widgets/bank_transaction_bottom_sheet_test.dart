import 'package:accountify/core/database/database.dart';
import 'package:accountify/core/providers/database_provider.dart';
import 'package:accountify/core/widgets/custom_cards_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('bank transaction bottom sheet does not create its own draggable sheet', (
    tester,
  ) async {
    const bank = Bank(
      id: 1,
      name: 'Telebirr',
      shortName: 'Telebirr',
      accountNumber: '0911223344',
      addressName: '127',
      icon: '',
      balance: 1200,
      received: 1500,
      sent: 300,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          transactionsWithBankListProvider(1).overrideWith((ref) async => []),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: BankTransactionBottomSheet(bank: bank),
          ),
        ),
      ),
    );

    expect(find.byType(DraggableScrollableSheet), findsNothing);
    expect(find.text('Transactions'), findsOneWidget);
  });
}
