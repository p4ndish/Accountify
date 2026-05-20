// test/core/utils/banks_message_parser_test.dart

import 'package:accountify/core/utils/banks_message_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BankMessageParser', () {
    // ========================================================================
    // TELEBIRR TESTS
    // ========================================================================
    group('Telebirr', () {
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

        test('CREDIT 2b: bank to telebirr from CBE', () {
          const message =
              'You have received  ETB 2,085.00 by transaction number CED3AFAZ8Z on 2025-05-13 12:40:36 from Commercial Bank of Ethiopia to your telebirr Account 251953511050';

          // Add balance line to make it parse
          const fullMessage = message +
              '. Your current balance is ETB 5,000.00.';

          final parser = BankMessageParser('Telebirr', fullMessage);
          final result = parser.parse();

          expect(result, isNotNull);
          expect(result!.name, 'From Commercial Bank of Ethiopia');
          expect(result.amount, 2085.00);
          expect(result.referenceCode, 'CED3AFAZ8Z');
        });
      });

      group('DEBIT patterns', () {
        test('DEBIT 1: peer-to-peer transfer', () {
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

        test('DEBIT 2: telebirr to bank account (CBE)', () {
          const message =
              'Dear DAGIM\nYou have transferred ETB 515.00 successfully from your telebirr account 251953511050 to Commercial Bank of Ethiopia account number 1000157013347 on 28/02/2026 15:09:28. Your telebirr transaction number is DBS1A73QF5 and your bank transaction number is FT26059FT3QD. The service fee is  ETB 5.22 and  15% VAT on the service fee is ETB 0.78. Your current balance is ETB 3,946.27.';

          final parser = BankMessageParser('Telebirr', message);
          final result = parser.parse();

          expect(result, isNotNull);
          expect(result!.name, 'To Commercial Bank of Ethiopia');
          expect(result.amount, 515.00);
          expect(result.balanceAfter, 3946.27);
          expect(result.transactionType, 'debited');
          expect(result.referenceCode, 'DBS1A73QF5'); // telebirr txn#
        });

        test('DEBIT 2b: telebirr to bank account (BOA)', () {
          const message =
              'You have transferred ETB 75.00 successfully from your telebirr account 251953511050 to Bank of Abyssinia account number 130186947 on 23/08/2025 10:30:00. Your telebirr transaction number is CHN0D6E64C. Your current balance is ETB 546.12.';

          final parser = BankMessageParser('Telebirr', message);
          final result = parser.parse();

          expect(result, isNotNull);
          expect(result!.name, 'To Bank of Abyssinia');
          expect(result.amount, 75.00);
          expect(result.referenceCode, 'CHN0D6E64C');
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
        });

        test('DEBIT 3b: voice package purchase', () {
          const message =
              'You have paid ETB 75.00 for package Voice Monthly for 228 +114 Min night package bonus purchase made for 912358815 on 24/02/2026 10:00:00. Your transaction number is  DBO55Q7VND. Your current balance is ETB 4,578.27.';

          final parser = BankMessageParser('Telebirr', message);
          final result = parser.parse();

          expect(result, isNotNull);
          expect(result!.name, 'Voice Monthly for 228 +114 Min night package bonus');
          expect(result.amount, 75.00);
          expect(result.referenceCode, 'DBO55Q7VND');
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
        });
      });

      group('SKIP patterns', () {
        test('SKIP: lottery ticket', () {
          const message =
              'You have received 1 point and 1 lottery ticket. Lottery ID: PL2030108969821473.';
          final parser = BankMessageParser('Telebirr', message);
          expect(parser.parse(), isNull);
        });

        test('SKIP: OTP', () {
          const message =
              'Dear Customer, 366237 is your telebirr verification code.';
          final parser = BankMessageParser('Telebirr', message);
          expect(parser.parse(), isNull);
        });

        test('SKIP: ATM withdrawal secret code', () {
          const message =
              'Your ATM withdrawal secret code is 714387 for an amount of ETB 2,000.00.';
          final parser = BankMessageParser('Telebirr', message);
          expect(parser.parse(), isNull);
        });

        test('SKIP: insufficient balance', () {
          const message =
              'Sorry, You have insufficient balance for the requested transaction.';
          final parser = BankMessageParser('Telebirr', message);
          expect(parser.parse(), isNull);
        });

        test('SKIP: unsuccessful transaction', () {
          const message = 'Your request to buy package was unsuccessful';
          final parser = BankMessageParser('Telebirr', message);
          expect(parser.parse(), isNull);
        });

        test('SKIP: airtime received (no wallet balance)', () {
          const message =
              'You have received ETB 1.00 airtime from 251953511050';
          final parser = BankMessageParser('Telebirr', message);
          expect(parser.parse(), isNull);
        });

        test('SKIP: credit payment', () {
          const message =
              'your outstanding Credit amount has been paid successfully.';
          final parser = BankMessageParser('Telebirr', message);
          expect(parser.parse(), isNull);
        });

        test('SKIP: Financial Marketplace', () {
          const message =
              'You have successfully activated the Financial Marketplace service.';
          final parser = BankMessageParser('Telebirr', message);
          expect(parser.parse(), isNull);
        });
      });
    });

    // ========================================================================
    // CBE TESTS
    // ========================================================================
    group('CBE', () {
      group('DEBIT patterns', () {
        test('DEBIT FORMAT A: with service charge', () {
          const message =
              'Dear Dagim your Account 1*********5207 has been debited with ETB2,085.00 .Service charge of  ETB10 and VAT(15%) of ETB1.50 with a total of ETB2096. Your Current Balance is ETB 0.95. Thank you for Banking with CBE! https://apps.cbe.com.et:100/?id=FT251337MK8175325207';

          final parser = BankMessageParser('CBE', message);
          final result = parser.parse();

          expect(result, isNotNull);
          expect(result!.transactionType, 'debited');
          expect(result.amount, 2085.00); // NOT the total with fee
          expect(result.balanceAfter, 0.95);
          expect(result.referenceCode, 'FT251337MK8175325207');
          expect(result.paymentLink, 'https://apps.cbe.com.et:100/?id=FT251337MK8175325207');
        });

        test('DEBIT FORMAT A variant: including service charge', () {
          const message =
              'Dear Dagim your Account 1*********5207 has been debited with ETB 401.61 including Service charge ETB1.40 and VAT(15%) ETB0.21. Your Current Balance is ETB 1952.1. Thank you for Banking with CBE!';

          final parser = BankMessageParser('CBE', message);
          final result = parser.parse();

          expect(result, isNotNull);
          expect(result!.transactionType, 'debited');
          expect(result.amount, 401.61);
          expect(result.balanceAfter, 1952.1);
        });

        test('DEBIT FORMAT B: simple debit', () {
          const message =
              'Dear Dagim your Account 1********5207 has been debited with ETB 100.57. Your Current Balance is ETB 1399.47. Thank you for Banking with CBE!';

          final parser = BankMessageParser('CBE', message);
          final result = parser.parse();

          expect(result, isNotNull);
          expect(result!.transactionType, 'debited');
          expect(result.amount, 100.57);
          expect(result.balanceAfter, 1399.47);
          expect(result.name, 'CBE Debit');
        });

        test('DEBIT FORMAT B: mobile banking fee', () {
          const message =
              'Dear Dagim your Account 1********5207 has been debited with ETB 5.75. Info: Mobile Banking Monthly Service Fee including VAT(15%) ETB0.75. Your Current Balance is ETB 1045.69.';

          final parser = BankMessageParser('CBE', message);
          final result = parser.parse();

          expect(result, isNotNull);
          expect(result!.transactionType, 'debited');
          expect(result.amount, 5.75);
          expect(result.name, 'Mobile Banking Fee');
        });
      });

      group('CREDIT patterns', () {
        test('CREDIT: account credited', () {
          const message =
              'Dear Dagim your Account 1********5207 has been credited with ETB 5019.00. Your Current Balance is ETB 5393.45. Thank you for Banking with CBE!';

          final parser = BankMessageParser('CBE', message);
          final result = parser.parse();

          expect(result, isNotNull);
          expect(result!.transactionType, 'credited');
          expect(result.amount, 5019.00);
          expect(result.balanceAfter, 5393.45);
          expect(result.name, 'CBE Credit');
        });

        test('CREDIT with URL', () {
          const message =
              'Dear Dagim your Account 1*********5207 has been Credited with ETB 200.00. Your Current Balance is ETB 374.45 Thank you for Banking with CBE! https://apps.cbe.com.et:100/?id=FT25128MJKNB75325207';

          final parser = BankMessageParser('CBE', message);
          final result = parser.parse();

          expect(result, isNotNull);
          expect(result!.transactionType, 'credited');
          expect(result.amount, 200.00);
          expect(result.referenceCode, 'FT25128MJKNB75325207');
        });
      });

      group('SKIP patterns', () {
        test('SKIP: OTP', () {
          const message =
              'Your OTP is 750801. Do not share with anyone. It is valid for 5 minutes.';
          final parser = BankMessageParser('CBE', message);
          expect(parser.parse(), isNull);
        });

        test('SKIP: app download', () {
          const message =
              'Please download CBE Android application from Market Place and use Key AA9TA49YQUVRVW';
          final parser = BankMessageParser('CBE', message);
          expect(parser.parse(), isNull);
        });
      });
    });

    // ========================================================================
    // BOA TESTS
    // ========================================================================
    group('BOA', () {
      group('DEBIT patterns', () {
        test('BOA DEBIT', () {
          const message =
              'Dear DAGIM, your account 1*****79 was debited with ETB 1,301.50. Available Balance:  ETB 31.46. Receipt: https://cs.bankofabyssinia.com/slip/?trx=FT26013HS3Z502879 \nFeedback: https://cs.bankofabyssinia.com/cs/?trx=DFT26013HS3Z5 For help, call 8397 (24/7 Toll-Free). Bank of Abyssinia.';

          final parser = BankMessageParser('BOA', message);
          final result = parser.parse();

          expect(result, isNotNull);
          expect(result!.transactionType, 'debited');
          expect(result.amount, 1301.50);
          expect(result.balanceAfter, 31.46);
          expect(result.referenceCode, 'FT26013HS3Z502879'); // slip URL, not feedback
          expect(result.name, 'BOA Debit');
          expect(result.paymentLink, 'https://cs.bankofabyssinia.com/slip/?trx=FT26013HS3Z502879');
        });
      });

      group('CREDIT patterns', () {
        test('BOA CREDIT with settlement info', () {
          const message =
              'Dear DAGIM, your account 1*****79 was credited with ETB 12,540.00 by A/R - P2P incoming settlement accou. Available Balance:  ETB 20,556.09. Receipt: https://cs.bankofabyssinia.com/slip/?trx=FT2534330QV910104';

          final parser = BankMessageParser('BOA', message);
          final result = parser.parse();

          expect(result, isNotNull);
          expect(result!.transactionType, 'credited');
          expect(result.amount, 12540.00);
          expect(result.balanceAfter, 20556.09);
          expect(result.name, 'A/R - P2P incoming settlement accou');
          expect(result.referenceCode, 'FT2534330QV910104');
        });

        test('BOA CREDIT from person', () {
          const message =
              'Dear DAGIM, your account 9*****38 was credited with ETB 10.00 by DAGIM TESFAYE CHANYALEW. Available Balance:  ETB 62.80. Receipt: https://cs.bankofabyssinia.com/slip/?trx=FT25339WXQWQ02879';

          final parser = BankMessageParser('BOA', message);
          final result = parser.parse();

          expect(result, isNotNull);
          expect(result!.transactionType, 'credited');
          expect(result.amount, 10.00);
          expect(result.name, 'DAGIM TESFAYE CHANYALEW');
          expect(result.balanceAfter, 62.80);
        });
      });

      group('SKIP patterns', () {
        test('SKIP: token number', () {
          const message = 'Your token number for today is U0229.';
          final parser = BankMessageParser('BOA', message);
          expect(parser.parse(), isNull);
        });

        test('SKIP: OTP', () {
          const message = 'Your otp is : 682941';
          final parser = BankMessageParser('BOA', message);
          expect(parser.parse(), isNull);
        });

        test('SKIP: Activation Code', () {
          const message =
              'The Activation Code for the service you have requested is: 6651';
          final parser = BankMessageParser('BOA', message);
          expect(parser.parse(), isNull);
        });

        test('SKIP: Mobile Banking PIN', () {
          const message =
              'Dear Bank of Abyssinia Customer, 1928 is the PIN for your Mobile Banking Service.';
          final parser = BankMessageParser('BOA', message);
          expect(parser.parse(), isNull);
        });

        test('SKIP: KYC approved', () {
          const message = 'Dear Customer, your KYC has been APPROVED.';
          final parser = BankMessageParser('BOA', message);
          expect(parser.parse(), isNull);
        });
      });
    });

    // ========================================================================
    // AWASH BANK TESTS
    // ========================================================================
    group('Awash Bank', () {
      test('returns null for unimplemented parser', () {
        const message = 'Some transaction message';
        final parser = BankMessageParser('AWASH', message);
        expect(parser.parse(), isNull);
      });
    });

    // ========================================================================
    // UNKNOWN BANK TESTS
    // ========================================================================
    group('Unknown bank', () {
      test('returns null for unknown bank', () {
        const message = 'Some transaction message';
        final parser = BankMessageParser('UnknownBank', message);
        expect(parser.parse(), isNull);
      });
    });

    // ========================================================================
    // EDGE CASES
    // ========================================================================
    group('Edge cases', () {
      test('handles double spaces in balance line', () {
        const message =
            'Dear DAGIM \nYou have recharged ETB 1.00 airtime for 983912998 on 02/03/2026 19:05:57. Your transaction number is DC27COFOU7. Your current  balance is  ETB 3,226.27.';

        final parser = BankMessageParser('Telebirr', message);
        final result = parser.parse();

        expect(result, isNotNull);
        expect(result!.balanceAfter, 3226.27);
      });

      test('CBE balance without space after ETB', () {
        // CBE sometimes sends balances like "ETB0.95" without space
        const message =
            'Dear Dagim your Account 1*********5207 has been debited with ETB2,085.00 .Service charge of  ETB10. Your Current Balance is ETB0.95. Thank you for Banking with CBE!';

        final parser = BankMessageParser('CBE', message);
        final result = parser.parse();

        expect(result, isNotNull);
        expect(result!.balanceAfter, 0.95);
      });

      test('CBE balance without space', () {
        const message =
            'Dear Dagim your Account 1*********5207 has been debited with ETB2,085.00. Your Current Balance is ETB0.95.';

        final parser = BankMessageParser('CBE', message);
        final result = parser.parse();

        expect(result, isNotNull);
        expect(result!.balanceAfter, 0.95);
      });
    });
  });
}
