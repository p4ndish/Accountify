// test/bank_message_parser_test.dart

import 'package:accountify/core/utils/banks_message_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BankMessageParser - Telebirr', () {
    group('CREDIT patterns', () {
      test('CREDIT 1: peer-to-peer received from person', () {
        const message =
            'Dear DAGIM \nYou have received ETB 18,900.00 from abdi bulti(2519****0093)  on 12/02/2026 11:46:14. Your transaction number is DBC5P8Z7W3. Your current E-Money Account balance is ETB 22,935.92.\nThank you for using telebirr';

        final parser = BankMessageParser('Telebirr', message);
        final result = parser.parse();

        expect(result, isNotNull);
        expect(result!.name, 'abdi bulti');
        expect(result.amount, 18900.00);
        expect(result.balanceAfter, 22935.92);
        expect(result.transactionType, 'credited');
        expect(result.referenceCode, 'DBC5P8Z7W3');
        expect(result.date.day, 12);
        expect(result.date.month, 2);
        expect(result.date.year, 2026);
      });

      test('CREDIT 2: bank to telebirr transfer', () {
        const message =
            'Dear DAGIM,\nYou have received  ETB 1,290.00 by transaction number DAD2S6JJU0 on 2026-01-13 16:54:58 from Bank of Abyssinia to your telebirr Account 251953511050 - DAGIM TESFAYE CHANYALEW. Your current balance is ETB 1,598.77.';

        final parser = BankMessageParser('Telebirr', message);
        final result = parser.parse();

        expect(result, isNotNull);
        expect(result!.name, 'From Bank of Abyssinia');
        expect(result.amount, 1290.00);
        expect(result.balanceAfter, 1598.77);
        expect(result.transactionType, 'credited');
        expect(result.referenceCode, 'DAD2S6JJU0');
        expect(result.date.year, 2026);
        expect(result.date.month, 1);
        expect(result.date.day, 13);
      });
    });

    group('DEBIT patterns', () {
      test('DEBIT 1: peer-to-peer transfer to person', () {
        const message =
            'Dear DAGIM \nYou have transferred ETB 360.00 to FEKERA TASEFAYE (2519****2244) on 01/03/2026 19:24:08. Your transaction number is DC14BLJ7DI. The service fee is  ETB 1.74 and  15% VAT on the service fee is ETB 0.26. Your current E-Money Account  balance is ETB 3,227.27.';

        final parser = BankMessageParser('Telebirr', message);
        final result = parser.parse();

        expect(result, isNotNull);
        expect(result!.name, 'FEKERA TASEFAYE');
        expect(result.amount, 360.00); // NOT including fee
        expect(result.balanceAfter, 3227.27);
        expect(result.transactionType, 'debited');
        expect(result.referenceCode, 'DC14BLJ7DI');
        expect(result.date.day, 1);
        expect(result.date.month, 3);
        expect(result.date.year, 2026);
      });

      test('DEBIT 2: telebirr to bank account', () {
        const message =
            'Dear DAGIM\nYou have transferred ETB 515.00 successfully from your telebirr account 251953511050 to Commercial Bank of Ethiopia account number 1000157013347 on 28/02/2026 15:09:28. Your telebirr transaction number is DBS1A73QF5 and your bank transaction number is FT26059FT3QD. The service fee is  ETB 5.22 ...  Your current balance is ETB 3,946.27.';

        final parser = BankMessageParser('Telebirr', message);
        final result = parser.parse();

        expect(result, isNotNull);
        expect(result!.name, 'To Commercial Bank of Ethiopia');
        expect(result.amount, 515.00);
        expect(result.balanceAfter, 3946.27);
        expect(result.transactionType, 'debited');
        expect(result.referenceCode, 'DBS1A73QF5'); // telebirr txn#
        expect(result.date.day, 28);
        expect(result.date.month, 2);
        expect(result.date.year, 2026);
      });

      test('DEBIT 3: package purchase', () {
        const message =
            'Dear DAGIM\nYou have paid ETB 5.00 for package Daily Birr 5 for 120 MB purchase made for 251953511050 on 01/03/2026 18:48:49. Your transaction number is  DC10BK29O4. Your current balance is ETB 3,589.27.';

        final parser = BankMessageParser('Telebirr', message);
        final result = parser.parse();

        expect(result, isNotNull);
        expect(result!.name, 'Daily Birr 5 for 120 MB');
        expect(result.amount, 5.00);
        expect(result.balanceAfter, 3589.27);
        expect(result.transactionType, 'debited');
        expect(result.referenceCode, 'DC10BK29O4');
        expect(result.date.day, 1);
        expect(result.date.month, 3);
        expect(result.date.year, 2026);
      });

      test('DEBIT 4: airtime recharge', () {
        const message =
            'Dear DAGIM \nYou have recharged ETB 1.00 airtime for 983912998 on 02/03/2026 19:05:57. Your transaction number is DC27COFOU7. Your current  balance is  ETB 3,226.27.';

        final parser = BankMessageParser('Telebirr', message);
        final result = parser.parse();

        expect(result, isNotNull);
        expect(result!.name, 'Airtime for 983912998');
        expect(result.amount, 1.00);
        expect(result.balanceAfter, 3226.27);
        expect(result.transactionType, 'debited');
        expect(result.referenceCode, 'DC27COFOU7');
        expect(result.date.day, 2);
        expect(result.date.month, 3);
        expect(result.date.year, 2026);
      });
    });

    group('SKIP patterns (should return null)', () {
      test('SKIP: lottery ticket / received points', () {
        const message =
            'Dear DAGIM, you have received 1 point for lottery ticket purchase.';
        final parser = BankMessageParser('Telebirr', message);
        expect(parser.parse(), isNull);
      });

      test('SKIP: verification code / OTP', () {
        const message =
            'Dear DAGIM, your telebirr verification code is 123456. Do not share this code.';
        final parser = BankMessageParser('Telebirr', message);
        expect(parser.parse(), isNull);
      });

      test('SKIP: ATM withdrawal secret code', () {
        const message =
            'Dear DAGIM, your ATM withdrawal secret code is 1234. Use within 15 minutes.';
        final parser = BankMessageParser('Telebirr', message);
        expect(parser.parse(), isNull);
      });

      test('SKIP: insufficient balance', () {
        const message =
            'Dear DAGIM, your transaction failed due to insufficient balance.';
        final parser = BankMessageParser('Telebirr', message);
        expect(parser.parse(), isNull);
      });

      test('SKIP: unsuccessful transaction', () {
        const message =
            'Dear DAGIM, your transfer was unsuccessful. Please try again.';
        final parser = BankMessageParser('Telebirr', message);
        expect(parser.parse(), isNull);
      });

      test('SKIP: airtime received (no wallet balance)', () {
        const message =
            'Dear DAGIM, You have received ETB 10.00 airtime from 2519****1111. Your airtime balance is now ETB 25.00.';
        final parser = BankMessageParser('Telebirr', message);
        expect(parser.parse(), isNull);
      });

      test('SKIP: credit payment (no balance line)', () {
        const message =
            'Dear DAGIM, your outstanding Credit amount has been paid successfully. The paid amount is ETB 1,072.20';
        final parser = BankMessageParser('Telebirr', message);
        expect(parser.parse(), isNull);
      });

      test('SKIP: invitation code', () {
        const message =
            'Dear DAGIM, your telebirr invitation code is ABC123. Share with friends.';
        final parser = BankMessageParser('Telebirr', message);
        expect(parser.parse(), isNull);
      });

      test('SKIP: Financial Marketplace', () {
        const message =
            'Dear DAGIM, welcome to telebirr Financial Marketplace. Explore our services.';
        final parser = BankMessageParser('Telebirr', message);
        expect(parser.parse(), isNull);
      });
    });

    group('Edge cases', () {
      test('handles double spaces in balance line', () {
        const message =
            'Dear DAGIM \nYou have recharged ETB 1.00 airtime for 983912998 on 02/03/2026 19:05:57. Your transaction number is DC27COFOU7. Your current  balance is  ETB 3,226.27.';

        final parser = BankMessageParser('Telebirr', message);
        final result = parser.parse();

        expect(result, isNotNull);
        expect(result!.balanceAfter, 3226.27);
      });

      test('handles reference code with trailing period', () {
        const message =
            'Dear DAGIM \nYou have received ETB 100.00 from John Doe(2519****1111)  on 12/02/2026 11:46:14. Your transaction number is ABC123XYZ.. Your current E-Money Account balance is ETB 500.00.';

        final parser = BankMessageParser('Telebirr', message);
        final result = parser.parse();

        expect(result, isNotNull);
        expect(result!.referenceCode, 'ABC123XYZ'); // trailing periods stripped
      });

      test('uses provided timestamp when no date in SMS', () {
        // When message doesn't contain a recognizable date, use provided timestamp
        const message =
            'Dear DAGIM Your transaction number is ABC123 is complete. Your current E-Money Account balance is ETB 500.00.';

        final fallbackDate = DateTime(2026, 1, 15);
        final parser = BankMessageParser(
          'Telebirr', 
          message, 
          timestampMillis: fallbackDate.millisecondsSinceEpoch,
        );
        final result = parser.parse();

        // This message doesn't match any pattern (no amount, no proper structure)
        // so it should return null
        expect(result, isNull);
      });
    });
  });

  group('BankMessageParser - BOA', () {
    test('returns null for unimplemented BOA parser', () {
      const message = 'Your account was credited with ETB 1000.00';
      final parser = BankMessageParser('BOA', message);
      expect(parser.parse(), isNull);
    });
  });

  group('BankMessageParser - CBE', () {
    test('returns null for unimplemented CBE parser', () {
      const message = 'Your account has been credited with ETB 1000.00';
      final parser = BankMessageParser('CBE', message);
      expect(parser.parse(), isNull);
    });
  });

  group('BankMessageParser - Unknown bank', () {
    test('returns null for unknown bank', () {
      const message = 'Some transaction message';
      final parser = BankMessageParser('UnknownBank', message);
      expect(parser.parse(), isNull);
    });
  });
}
