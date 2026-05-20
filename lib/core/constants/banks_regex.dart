class BanksRegex {

  // BOA
  static final utilityWithdrawRegex = RegExp(
    r'(recharged|paid|payment|used).*?ETB\s([\d,]+\.\d{2}).*(airtime|utility|electricity|credit)',
    caseSensitive: false,
    dotAll: true,
  );
  static final boaWithdrawRegex = RegExp(
    r'(transferred|debited|paid|payment).*?ETB\s([\d,]+\.\d{2}).*?(to\s+Bank of Abyssinia|utility).*?transaction number\s+([A-Z0-9]+)',
    caseSensitive: false,
    dotAll: true,
  );
  static final boaReceivedRegex = RegExp(
    r'(received|credited)\s+ETB\s([\d,]+\.\d{2}).*?from\s+Bank of Abyssinia.*?transaction number\s+([A-Z0-9]+)',
    caseSensitive: false,
    dotAll: true,
  );

  // CBE
  static final cbeReceivedRegex = RegExp(
    r'(received|credited)\s+ETB\s([\d,]+\.\d{2}).*?from\s+Commercial Bank of Ethiopia.*?transaction number\s+([A-Z0-9]+)',
    caseSensitive: false,
    dotAll: true,
  );
  static final cbeWithdrawRegex = RegExp(
    r'(transferred|debited|paid|payment).*?ETB\s([\d,]+\.\d{2}).*?(to\s+Commercial Bank of Ethiopia|utility).*?transaction number\s+([A-Z0-9]+)',
    caseSensitive: false,
    dotAll: true,
  );

  static final urlRegex = RegExp(
    r'https?://\S+',
    caseSensitive: false,
  );

  static final boaTrxRegex = RegExp(
    r'trx=([A-Z0-9]+)',
    caseSensitive: false,
  );

  static final boaCreditDebitRegex = RegExp(
    r'was\s+(credited|debited)\s+with\s+ETB\s+([\d,]+(?:\.\d{1,2})?)',
    caseSensitive: false,
    dotAll: true,
  );

  static final cbeCreditDebitRegex = RegExp(
    r'has\s+been\s+(credited|debited)\s+with\s+ETB\s+([\d,]+(?:\.\d{1,2})?)',
    caseSensitive: false,
    dotAll: true,
  );


  /// TELEBIRR 
  
  // CREDITED: "You have received ETB X by transaction number Y on Z"
  static final telebirrReceivedByTrxRegex = RegExp(
    r'you\s+have\s+received\s+ETB\s+([\d,]+(?:\.\d{1,2})?)\s+by\s+transaction\s+number\s+([A-Z0-9]+)(?:\s+on\s+([0-9\-: ]{10,19}))?',
    caseSensitive: false,
    dotAll: true,
  );

  // CREDITED: "You have received ETB X from NAME on DATE" (person-to-person)
  static final telebirrReceivedFromPersonRegex = RegExp(
    r'you\s+have\s+received\s+ETB\s+([\d,]+(?:\.\d{1,2})?)\s+from\s+[^\d]+\s+on\s+([0-9/\-: ]{10,19}).*?transaction\s+number\s+(?:is\s+)?([A-Z0-9]+)',
    caseSensitive: false,
    dotAll: true,
  );

  // CREDITED: "Your telebirr account has been credited with ETB X"
  static final telebirrCreditedRegex = RegExp(
    r'telebirr\s+account\s+has\s+been\s+credited\s+with\s+ETB\s+([\d,]+(?:\.\d{1,2})?)',
    caseSensitive: false,
    dotAll: true,
  );

  // CREDITED: "You have received ETB X ... to your telebirr Account" (from bank)
  static final telebirrReceivedFromBankRegex = RegExp(
    r'you\s+have\s+received\s+ETB\s+([\d,]+(?:\.\d{1,2})?).*?transaction\s+number\s+([A-Z0-9]+)(?:\s+on\s+([0-9/\-: ]{10,19}))?.*?to\s+your\s+telebirr\s+Account',
    caseSensitive: false,
    dotAll: true,
  );

  // DEBITED: "You have transferred ETB X to NAME on DATE" (person-to-person)
  static final telebirrTransferToPersonRegex = RegExp(
    r'you\s+have\s+transferred\s+ETB\s+([\d,]+(?:\.\d{1,2})?)\s+to\s+[^\d]+\s+on\s+([0-9/\-: ]{10,19}).*?transaction\s+number\s+(?:is\s+)?([A-Z0-9]+)',
    caseSensitive: false,
    dotAll: true,
  );

  // DEBITED: "You have transferred ETB X successfully from your telebirr account ... to ... bank"
  static final telebirrTransferToBankRegex = RegExp(
    r'you\s+have\s+transferred\s+ETB\s+([\d,]+(?:\.\d{1,2})?)\s+successfully\s+from\s+your\s+telebirr.*?on\s+([0-9/\-: ]{10,19}).*?transaction\s+number\s+(?:is\s+)?([A-Z0-9]+)',
    caseSensitive: false,
    dotAll: true,
  );

  // DEBITED: "You have recharged ETB X airtime"
  static final telebirrRechargeRegex = RegExp(
    r'you\s+have\s+recharged\s+ETB\s+([\d,]+(?:\.\d{1,2})?)\s+airtime.*?on\s+([0-9/\-: ]{10,19}).*?transaction\s+number\s+(?:is\s+)?([A-Z0-9]+)',
    caseSensitive: false,
    dotAll: true,
  );

  // DEBITED: "You have paid ETB X for package"
  static final telebirrPackagePaymentRegex = RegExp(
    r'you\s+have\s+paid\s+ETB\s+([\d,]+(?:\.\d{1,2})?)\s+for\s+package.*?on\s+([0-9/\-: ]{10,19}).*?transaction\s+number\s+(?:is\s+)?([A-Z0-9]+)',
    caseSensitive: false,
    dotAll: true,
  );

  // DEBITED: "You have paid ETB X to pay bill" - UPDATED to make date optional
  static final telebirrBillPaymentRegex = RegExp(
    r'you\s+have\s+paid\s+ETB\s+([\d,]+(?:\.\d{1,2})?)\s+to\s+pay\s+bill.*?(?:on\s+([0-9/\-: ]{10,19}))?.*?transaction\s+number\s+(?:is\s+)?([A-Z0-9]+)',
    caseSensitive: false,
    dotAll: true,
  );

  // DEBITED: ATM withdrawal completion
  static final telebirrAtmCompletionRegex = RegExp(
    r'request\s+to\s+withdraw\s+ETB\s+([\d,]+(?:\.\d{1,2})?).*?on\s+([0-9/\-: ]{10,19}).*?transaction\s+number\s+([A-Z0-9]+)',
    caseSensitive: false,
    dotAll: true,
  );

  // NEW: DEBITED - "You have paid ETB X for goods purchased from MERCHANT"
  // Example: You have paid ETB 1.00 for goods purchased from 5063 - Santim Pay Financial Solution SC on 07/02/2026 05:07:34
  static final telebirrMerchantPaymentRegex = RegExp(
    r'you\s+have\s+paid\s+ETB\s+([\d,]+(?:\.\d{1,2})?)\s+for\s+goods\s+purchased\s+from\s+\d+\s+-\s+[^.]+?\s+on\s+([0-9/\-: ]{10,19}).*?transaction\s+number\s+(?:is\s+)?([A-Z0-9]+)',
    caseSensitive: false,
    dotAll: true,
  );

  // NEW: DEBITED - "You have paid ETB X to Ethiopian Electric Utility"
  // Example: You have paid ETB 11.60 to Ethiopian Electric Utility with Payment number 100000352415 on 19/02/2026 00:01:29
  static final telebirrUtilityPaymentRegex = RegExp(
    r'you\s+have\s+paid\s+ETB\s+([\d,]+(?:\.\d{1,2})?)\s+to\s+(?:Ethiopian Electric Utility|Addis Ababa Water|Safaricom|Ethio telecom).*?(?:with\s+Payment\s+number\s+(\d+))?.*?transaction\s+number\s+(?:is\s+)?([A-Z0-9]+)',
    caseSensitive: false,
    dotAll: true,
  );

  // NEW: DEBITED - Credit/Loan Payment
  // Example: your outstanding Credit amount has been paid successfully. The paid amount is ETB 1,072.20
  static final telebirrCreditPaymentRegex = RegExp(
    r'your\s+outstanding\s+credit\s+amount\s+has\s+been\s+paid\s+successfully.*?the\s+paid\s+amount\s+is\s+ETB\s+([\d,]+(?:\.\d{1,2})?)',
    caseSensitive: false,
    dotAll: true,
  );

  
  
}
