import 'package:another_telephony/telephony.dart';

class BankModel {
  final int id;
  final String name;
  final String shortName;
  final String icon;

  BankModel({required this.name, required this.shortName, required this.icon, required this.id});

  factory BankModel.fromSms(SmsMessage message) {
    // Parse SMS message to extract bank information
    // This is a placeholder implementation
    return BankModel(
      id: 1,
      name: 'Default Bank',
      shortName: 'DB',
      icon: 'assets/icons/bank.png',
    );
  }

  // BankModel({required this.name, required this.icon, required this.balance, required this.received, required this.sent});
}
