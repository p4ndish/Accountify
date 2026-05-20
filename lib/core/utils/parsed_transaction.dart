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

  const ParsedTransaction({
    required this.name,
    required this.amount,
    required this.balanceAfter,
    required this.transactionType,
    required this.referenceCode,
    required this.paymentLink,
    required this.date,
  });

  @override
  String toString() {
    return 'ParsedTransaction(name: $name, amount: $amount, balanceAfter: $balanceAfter, '
        'type: $transactionType, ref: $referenceCode, date: $date)';
  }
}
