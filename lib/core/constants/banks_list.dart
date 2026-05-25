import 'package:accountify/core/utils/images.dart';

class Constants { 
  static List<Map<String, String>> supportedBanks = [
    {'name': 'Telebirr', 'accountNumber': '', 'shortName': 'Telebirr', 'addressName': '127', 'icon': AppAssets.telebirrIcon},
    {'name': 'Commercial Bank of Ethiopia', 'accountNumber': '', 'shortName':'CBE', 'addressName': 'CBE', 'icon': AppAssets.cbeBankIcon},
    {'name': 'Bank of Abyssinia', 'accountNumber': '', 'shortName': 'BOA', 'addressName': 'BOA', 'icon': AppAssets.boaBankIcon},
    {'name': 'Awash Bank', 'accountNumber': '', 'shortName': 'AWASH', 'addressName': 'Awash Bank', 'icon': AppAssets.awashBankIcon},
    {'name': 'Dashen Bank', 'accountNumber': '', 'shortName': 'DASHEN', 'addressName': 'Dashen Bank', 'icon': AppAssets.dashenBankIcon}
  ];

  static List<String> customMonths = [
    'This Month',
    'This Week',
    DateTime.now().year.toString(),
    (DateTime.now().year - 1).toString(),  // Previous year
    '6 month',
    '3 month',
    
  ];
}