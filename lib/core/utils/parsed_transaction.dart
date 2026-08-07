// lib/core/utils/parsed_transaction.dart

/// Parsed transaction model for Ethiopian bank SMS messages
class ParsedTransaction {
  final String name;
  final double amount;
  final double balanceAfter;
  final String transactionType;
  final String referenceCode;
  final String paymentLink;
  final DateTime date;

  /// Transaction sub-type, used to classify the movement.
  /// One of: 'p2p', 'bank_in', 'bank_out', 'package', 'airtime', 'merchant',
  /// 'utility', 'bill', 'reversal', 'atm', or '' (unknown).
  ///
  /// 'bank_in' and 'bank_out' represent transfers between the user's own
  /// accounts (e.g. Telebirr <-> CBE). These are excluded from aggregate
  /// received/sent totals so internal movements are not double-counted.
  final String subType;

  /// The counterparty bank account number involved in a Telebirr<->bank
  /// transfer, when the SMS exposes it. Used at import time to detect true
  /// internal transfers (the counterparty account belongs to the user) so they
  /// can be tagged 'bank_in'/'bank_out' and excluded from aggregate totals.
  /// Empty when not applicable.
  final String counterpartyAccount;

  const ParsedTransaction({
    required this.name,
    required this.amount,
    required this.balanceAfter,
    required this.transactionType,
    required this.referenceCode,
    required this.paymentLink,
    required this.date,
    this.subType = '',
    this.counterpartyAccount = '',
  });

  @override
  String toString() {
    return 'ParsedTransaction(name: $name, amount: $amount, balanceAfter: $balanceAfter, '
        'type: $transactionType, ref: $referenceCode, subType: $subType, date: $date)';
  }
}
