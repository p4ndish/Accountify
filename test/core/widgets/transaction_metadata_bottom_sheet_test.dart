import 'package:accountify/core/widgets/transaction_metadata_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('saves selected fixed and custom tags', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: TransactionMetadataBottomSheet(
              transactionId: 1,
              title: 'FEKERA TASEFAYE',
              subtitle: '-ETB 360.00',
              predefinedTags: ['food', 'transfer', 'bills'],
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('food'));
    await tester.enterText(find.byKey(const Key('custom-tag-field')), 'friends');
    await tester.tap(find.text('Add tag'));
    await tester.pump();

    expect(find.text('friends'), findsOneWidget);
    expect(find.text('food'), findsOneWidget);
    expect(find.text('Save'), findsOneWidget);
  });
}
