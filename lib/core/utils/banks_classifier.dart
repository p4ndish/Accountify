

import 'package:accountify/core/constants/banks_regex.dart';

enum BankTxDirection { credited, debited }

BankTxDirection? classify(String body) {
  if ( BanksRegex.cbeReceivedRegex.hasMatch(body)) {
    return BankTxDirection.credited;
  }
  
  if (BanksRegex.cbeWithdrawRegex.hasMatch(body)) {
    return BankTxDirection.debited;
  }

  if (BanksRegex.boaReceivedRegex.hasMatch(body)) {
    return BankTxDirection.credited;
  }

  if (BanksRegex.boaWithdrawRegex.hasMatch(body)) {
    return BankTxDirection.debited;
  }
  
  if (BanksRegex.utilityWithdrawRegex.hasMatch(body)) {
    return BankTxDirection.debited;
  }

  // Telebirr credited patterns
  if (BanksRegex.telebirrReceivedByTrxRegex.hasMatch(body) ||
      BanksRegex.telebirrReceivedFromPersonRegex.hasMatch(body) ||
      BanksRegex.telebirrReceivedFromBankRegex.hasMatch(body) ||
      BanksRegex.telebirrCreditedRegex.hasMatch(body)) {
    return BankTxDirection.credited;
  }

  // Telebirr debited patterns
  if (BanksRegex.telebirrTransferToPersonRegex.hasMatch(body) ||
      BanksRegex.telebirrTransferToBankRegex.hasMatch(body) ||
      BanksRegex.telebirrRechargeRegex.hasMatch(body) ||
      BanksRegex.telebirrPackagePaymentRegex.hasMatch(body) ||
      BanksRegex.telebirrBillPaymentRegex.hasMatch(body) ||
      BanksRegex.telebirrAtmCompletionRegex.hasMatch(body)) {
    return BankTxDirection.debited;
  }
  return null;
}
