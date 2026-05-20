import 'package:accountify/core/utils/images.dart';

class Constants { 
  static List<Map<String, String>> supportedBanks = [
    {'name': 'Telebirr', 'accountNumber': '0911223344', 'shortName': 'Telebirr', 'addressName': '127', 'icon': AppAssets.telebirrIcon},
    {'name': 'Commercial Bank of Ethiopia', 'accountNumber': '549030300', 'shortName':'CBE', 'addressName': 'CBE', 'icon': AppAssets.cbeBankIcon},
    {'name': 'Bank of Abysiniya', 'accountNumber': '100012304343434', 'shortName': 'BOA', 'addressName': 'BOA', 'icon': AppAssets.cbeBankIcon},
    {'name': 'Awash Bank', 'accountNumber': '1234456456', 'shortName': 'AWASH', 'addressName': 'Awash Bank', 'icon': AppAssets.awashBankIcon},
    {'name': 'Dashen Bank', 'accountNumber': '776744', 'shortName': 'DASHEN', 'addressName': 'Dashen Bank', 'icon': AppAssets.dashenBankIcon}
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