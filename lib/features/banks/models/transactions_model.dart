class TransactionModel {
  final String name;
  final String icon;
  final bool isDebit;
  final double amount;
  final String date;
  final String bank;

  TransactionModel({required this.name, required this.icon, required this.isDebit, required this.amount, required this.date, required this.bank});
}