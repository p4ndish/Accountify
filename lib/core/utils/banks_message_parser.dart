// lib/core/utils/banks_message_parser.dart

import 'package:accountify/core/utils/parsed_transaction.dart';

/// Parser for Ethiopian bank SMS messages (Telebirr, CBE, BOA, Awash Bank)
class BankMessageParser {
  final String bankShortName;
  final String body;
  final int? timestampMillis;

  BankMessageParser(this.bankShortName, this.body, {this.timestampMillis});

  // ===========================================================================
  // SHARED UTILITIES
  // ===========================================================================

  /// Parse amount string: "18,900.00" → 18900.0
  static double? _parseAmount(String raw) {
    final cleaned = raw.replaceAll(',', '').trim();
    return double.tryParse(cleaned);
  }

  /// Date from timestamp millis, fallback to now
  DateTime _dateFromMillis() {
    return timestampMillis != null
        ? DateTime.fromMillisecondsSinceEpoch(timestampMillis!)
        : DateTime.now();
  }

  /// Parse DD/MM/YYYY HH:MM:SS format
  static DateTime? _parseDdMmYyyyHms(String value) {
    final trimmed = value.trim();
    final parts = trimmed.split(' ');
    if (parts.length != 2) return null;

    final d = parts[0].split('/');
    final t = parts[1].split(':');
    if (d.length != 3 || t.length != 3) return null;

    final day = int.tryParse(d[0]);
    final month = int.tryParse(d[1]);
    final year = int.tryParse(d[2]);
    final hour = int.tryParse(t[0]);
    final minute = int.tryParse(t[1]);
    final second = int.tryParse(t[2]);

    if (day == null || month == null || year == null) return null;
    if (hour == null || minute == null || second == null) return null;

    return DateTime(year, month, day, hour, minute, second);
  }

  /// Parse ISO-like date: "2026-01-13 16:54:58"
  static DateTime? _parseIsoLikeDate(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    final iso = trimmed.contains('T') ? trimmed : trimmed.replaceFirst(' ', 'T');
    return DateTime.tryParse(iso);
  }

  /// Extract first URL from text
  static String _extractUrl(String text) {
    final regex = RegExp(r'https?://\S+', caseSensitive: false);
    final match = regex.firstMatch(text);
    return match?.group(0)?.replaceAll(RegExp(r'[.,;]+$'), '') ?? '';
  }

  /// Generate fallback reference code when none found in message
  String _fallbackRef(String bankPrefix) {
    final ts = timestampMillis?.toString() ?? body.hashCode.toString();
    final amtMatch = RegExp(r'ETB\s*[\d,]+\.?\d*').firstMatch(body);
    final amt = amtMatch?.group(0)?.replaceAll(RegExp(r'[^\d.]'), '') ?? '';
    return '${bankPrefix}_${ts}_$amt';
  }

  // ===========================================================================
  // MAIN PARSE METHOD
  // ===========================================================================

  ParsedTransaction? parse() {
    switch (bankShortName) {
      case 'Telebirr':
        return _parseTelebirr();
      case 'CBE':
        return _parseCBE();
      case 'BOA':
        return _parseBOA();
      case 'AWASH':
        return _parseAwashBank();
      default:
        return null;
    }
  }

  // ===========================================================================
  // TELEBIRR PARSER (sender: 127)
  // ===========================================================================

  ParsedTransaction? _parseTelebirr() {
    // Skip non-transaction messages
    if (_shouldSkipTelebirr()) return null;

    // Try each transaction pattern
    final parsers = [
      _parseTelebirrCreditReceivedFromPerson,
      _parseTelebirrCreditReceivedFromBank,
      _parseTelebirrDebitTransferToPerson,
      _parseTelebirrDebitTransferToBank,
      _parseTelebirrDebitPackagePurchase,
      _parseTelebirrDebitAirtimeRecharge,
    ];

    for (final parser in parsers) {
      final result = parser();
      if (result != null) return result;
    }

    return null;
  }

  bool _shouldSkipTelebirr() {
    // Must have a balance line to be a real transaction
    final hasBalance = RegExp(
      r'current\s+(?:E-Money\s+Account\s+)?balance\s+is',
      caseSensitive: false,
    ).hasMatch(body);

    if (!hasBalance) return true;

    // Skip specific patterns
    final skipPatterns = [
      r'lottery\s+ticket',
      r'received\s+\d+\s+point',
      r'\bOTP\b',
      r'verification\s+code',
      r'ATM\s+withdrawal\s+secret\s+code',
      r'insufficient\s+balance',
      r'unsuccessful',
      r'incorrect\s+PIN',
      r'outstanding\s+[Cc]redit\s+amount',
      r'invitation\s+code',
      r'[Ff]inancial\s+[Mm]arketplace',
      r'airtime\s+from',
      r'account\s+ownership\s+verification',
    ];

    for (final pattern in skipPatterns) {
      if (body.contains(RegExp(pattern, caseSensitive: false))) return true;
    }

    return false;
  }

  /// CREDIT 1: Peer-to-peer received from person
  ParsedTransaction? _parseTelebirrCreditReceivedFromPerson() {
    final regex = RegExp(
      r'You\s+have\s+received\s+ETB\s+([\d,]+\.?\d*)\s+from\s+([^()\n]+?)(?:\s*\(\d+\*{4}\d+\))?\s+on\s+([\d/]+\s+[\d:]+)\.\s*Your\s+transaction\s+number\s+is\s+([A-Z0-9]+)\.?\s*Your\s+current\s+E-Money\s+Account\s+balance\s+is\s+ETB\s+([\d,]+\.?\d*)',
      caseSensitive: false,
      dotAll: true,
    );

    final match = regex.firstMatch(body);
    if (match == null) return null;

    final amount = _parseAmount(match.group(1)!);
    final name = match.group(2)!.trim();
    final dateStr = match.group(3)!;
    final refCode = match.group(4)!.replaceAll('.', '');
    final balance = _parseAmount(match.group(5)!);

    if (amount == null || balance == null) return null;

    final date = _parseDdMmYyyyHms(dateStr) ?? _dateFromMillis();

    return ParsedTransaction(
      name: name,
      amount: amount,
      balanceAfter: balance,
      transactionType: 'credited',
      referenceCode: refCode,
      paymentLink: _extractUrl(body),
      date: date,
    );
  }

  /// CREDIT 2: Bank to telebirr transfer
  ParsedTransaction? _parseTelebirrCreditReceivedFromBank() {
    final regex = RegExp(
      r'You\s+have\s+received\s+ETB\s+([\d,]+\.?\d*)\s+by\s+transaction\s+number\s+([A-Z0-9]+)\s+on\s+([\d\-:\s]+)\s+from\s+(.+?)\s+to\s+your\s+telebirr.*?Your\s+current\s+balance\s+is\s+ETB\s+([\d,]+\.?\d*)',
      caseSensitive: false,
      dotAll: true,
    );

    final match = regex.firstMatch(body);
    if (match == null) return null;

    final amount = _parseAmount(match.group(1)!);
    final refCode = match.group(2)!;
    final dateStr = match.group(3)!.trim();
    final bankName = match.group(4)!.trim();
    final balance = _parseAmount(match.group(5)!);

    if (amount == null || balance == null) return null;

    final date = _parseIsoLikeDate(dateStr) ?? _dateFromMillis();

    return ParsedTransaction(
      name: 'From $bankName',
      amount: amount,
      balanceAfter: balance,
      transactionType: 'credited',
      referenceCode: refCode,
      paymentLink: _extractUrl(body),
      date: date,
    );
  }

  /// DEBIT 1: Peer-to-peer transfer
  ParsedTransaction? _parseTelebirrDebitTransferToPerson() {
    final regex = RegExp(
      r'You\s+have\s+transferred\s+ETB\s+([\d,]+\.?\d*)\s+to\s+([^()\n]+?)(?:\s*\(\d+\*{4}\d+\))?\s+on\s+([\d/]+\s+[\d:]+)\.\s*Your\s+transaction\s+number\s+is\s+([A-Z0-9]+)\.?.*?Your\s+current\s+(?:E-Money\s+Account\s+)?balance\s+is\s+ETB\s+([\d,]+\.?\d*)',
      caseSensitive: false,
      dotAll: true,
    );

    final match = regex.firstMatch(body);
    if (match == null) return null;

    final amount = _parseAmount(match.group(1)!);
    final name = match.group(2)!.trim();
    final dateStr = match.group(3)!;
    final refCode = match.group(4)!.replaceAll('.', '');
    final balance = _parseAmount(match.group(5)!);

    if (amount == null || balance == null) return null;

    final date = _parseDdMmYyyyHms(dateStr) ?? _dateFromMillis();

    return ParsedTransaction(
      name: name,
      amount: amount,
      balanceAfter: balance,
      transactionType: 'debited',
      referenceCode: refCode,
      paymentLink: _extractUrl(body),
      date: date,
    );
  }

  /// DEBIT 2: Telebirr to bank account
  ParsedTransaction? _parseTelebirrDebitTransferToBank() {
    final regex = RegExp(
      r'You\s+have\s+transferred\s+ETB\s+([\d,]+\.?\d*)\s+successfully\s+from\s+your\s+telebirr\s+account\s+\d+\s+to\s+(.+?)\s+account\s+number\s+\d+\s+on\s+([\d/]+\s+[\d:]+)\.\s*Your\s+telebirr\s+transaction\s+number\s+is\s+([A-Z0-9]+)\.?.*?Your\s+current\s+balance\s+is\s+ETB\s+([\d,]+\.?\d*)',
      caseSensitive: false,
      dotAll: true,
    );

    final match = regex.firstMatch(body);
    if (match == null) return null;

    final amount = _parseAmount(match.group(1)!);
    final bankName = match.group(2)!.trim();
    final dateStr = match.group(3)!;
    final refCode = match.group(4)!;
    final balance = _parseAmount(match.group(5)!);

    if (amount == null || balance == null) return null;

    final date = _parseDdMmYyyyHms(dateStr) ?? _dateFromMillis();

    return ParsedTransaction(
      name: 'To $bankName',
      amount: amount,
      balanceAfter: balance,
      transactionType: 'debited',
      referenceCode: refCode,
      paymentLink: _extractUrl(body),
      date: date,
    );
  }

  /// DEBIT 3: Package purchase
  ParsedTransaction? _parseTelebirrDebitPackagePurchase() {
    final regex = RegExp(
      r'You\s+have\s+paid\s+ETB\s+([\d,]+\.?\d*)\s+for\s+package\s+(.+?)\s+(?:purchase|renewal)\s+made\s+for\s+\d+\s+on\s+([\d/]+\s+[\d:]+)\.?\s*Your\s+transaction\s+number\s+is\s+([A-Z0-9]+)\.?\s*Your\s+current\s+balance\s+is\s+ETB\s+([\d,]+\.?\d*)',
      caseSensitive: false,
      dotAll: true,
    );

    final match = regex.firstMatch(body);
    if (match == null) return null;

    final amount = _parseAmount(match.group(1)!);
    final packageName = match.group(2)!.trim();
    final dateStr = match.group(3)!;
    final refCode = match.group(4)!.replaceAll('.', '');
    final balance = _parseAmount(match.group(5)!);

    if (amount == null || balance == null) return null;

    final date = _parseDdMmYyyyHms(dateStr) ?? _dateFromMillis();

    return ParsedTransaction(
      name: packageName,
      amount: amount,
      balanceAfter: balance,
      transactionType: 'debited',
      referenceCode: refCode,
      paymentLink: _extractUrl(body),
      date: date,
    );
  }

  /// DEBIT 4: Airtime recharge
  ParsedTransaction? _parseTelebirrDebitAirtimeRecharge() {
    final regex = RegExp(
      r'You\s+have\s+recharged\s+ETB\s+([\d,]+\.?\d*)\s+airtime\s+for\s+(\d+)\s+on\s+([\d/]+\s+[\d:]+)\.?\s*Your\s+transaction\s+number\s+is\s+([A-Z0-9]+)\.?\s*Your\s+current\s+balance\s+is\s+ETB\s+([\d,]+\.?\d*)',
      caseSensitive: false,
      dotAll: true,
    );

    final match = regex.firstMatch(body);
    if (match == null) return null;

    final amount = _parseAmount(match.group(1)!);
    final phoneNumber = match.group(2)!;
    final dateStr = match.group(3)!;
    final refCode = match.group(4)!.replaceAll('.', '');
    final balance = _parseAmount(match.group(5)!);

    if (amount == null || balance == null) return null;

    final date = _parseDdMmYyyyHms(dateStr) ?? _dateFromMillis();

    return ParsedTransaction(
      name: 'Airtime for $phoneNumber',
      amount: amount,
      balanceAfter: balance,
      transactionType: 'debited',
      referenceCode: refCode,
      paymentLink: _extractUrl(body),
      date: date,
    );
  }

  // ===========================================================================
  // CBE PARSER (sender: CBE)
  // ===========================================================================

  ParsedTransaction? _parseCBE() {
    // Skip non-transaction messages
    if (_shouldSkipCBE()) return null;

    final parsers = [
      _parseCBEDebitFormatA,
      _parseCBEDebitFormatB,
      _parseCBECredit,
    ];

    for (final parser in parsers) {
      final result = parser();
      if (result != null) return result;
    }

    return null;
  }

  bool _shouldSkipCBE() {
    // Must contain transaction keywords
    final hasTransaction = RegExp(
      r'has been (?:debited|credited|Credited)',
      caseSensitive: false,
    ).hasMatch(body);

    if (!hasTransaction) return true;

    // Skip OTP and promotional
    final skipPatterns = [
      r'\bOTP\b',
      r'Please download',
    ];

    for (final pattern in skipPatterns) {
      if (body.contains(RegExp(pattern, caseSensitive: false))) return true;
    }

    return false;
  }

  /// CBE DEBIT FORMAT A: with service charge breakdown
  ParsedTransaction? _parseCBEDebitFormatA() {
    // Pattern with "Service charge of" or "including Service charge"
    // Account can be masked like "1*********5207" or "1********5207"
    final regex = RegExp(
      r'Account\s+[\d*]+\s+has been debited with ETB\s*([\d,]+\.?\d*).*?(?:Service charge|including Service charge).*?Your Current Balance is ETB\s*([\d,]+\.?\d*)',
      caseSensitive: false,
      dotAll: true,
    );

    final match = regex.firstMatch(body);
    if (match == null) return null;

    final amount = _parseAmount(match.group(1)!);
    final balance = _parseAmount(match.group(2)!);

    if (amount == null || balance == null) return null;

    // Extract reference from URL
    final urlRefRegex = RegExp(r'id=(FT[A-Z0-9]+)');
    final urlMatch = urlRefRegex.firstMatch(body);
    final refCode = urlMatch?.group(1) ?? _fallbackRef('CBE');

    // Determine name based on message content
    String name = 'CBE Debit';
    if (body.toLowerCase().contains('mobile banking monthly service fee')) {
      name = 'Mobile Banking Fee';
    }

    return ParsedTransaction(
      name: name,
      amount: amount,
      balanceAfter: balance,
      transactionType: 'debited',
      referenceCode: refCode,
      paymentLink: _extractUrl(body),
      date: _dateFromMillis(),
    );
  }

  /// CBE DEBIT FORMAT B: simple debit (no service charge details)
  ParsedTransaction? _parseCBEDebitFormatB() {
    final regex = RegExp(
      r'Account\s+[\d*]+\s+has been debited with ETB\s*([\d,]+\.?\d*)\.\s*(?:Info:.*?)?Your Current Balance is ETB\s*([\d,]+\.?\d*)',
      caseSensitive: false,
      dotAll: true,
    );

    final match = regex.firstMatch(body);
    if (match == null) return null;

    final amount = _parseAmount(match.group(1)!);
    final balance = _parseAmount(match.group(2)!);

    if (amount == null || balance == null) return null;

    // Extract reference from URL
    final urlRefRegex = RegExp(r'id=(FT[A-Z0-9]+)');
    final urlMatch = urlRefRegex.firstMatch(body);
    final refCode = urlMatch?.group(1) ?? _fallbackRef('CBE');

    String name = 'CBE Debit';
    if (body.toLowerCase().contains('mobile banking monthly service fee')) {
      name = 'Mobile Banking Fee';
    }

    return ParsedTransaction(
      name: name,
      amount: amount,
      balanceAfter: balance,
      transactionType: 'debited',
      referenceCode: refCode,
      paymentLink: _extractUrl(body),
      date: _dateFromMillis(),
    );
  }

  /// CBE CREDIT: account credited
  ParsedTransaction? _parseCBECredit() {
    final regex = RegExp(
      r'Account\s+[\d*]+\s+has been (?:credited|Credited) with ETB\s*([\d,]+\.?\d*)\.\s*Your Current Balance is ETB\s*([\d,]+\.?\d*)',
      caseSensitive: false,
      dotAll: true,
    );

    final match = regex.firstMatch(body);
    if (match == null) return null;

    final amount = _parseAmount(match.group(1)!);
    final balance = _parseAmount(match.group(2)!);

    if (amount == null || balance == null) return null;

    // Extract reference from URL
    final urlRefRegex = RegExp(r'id=(FT[A-Z0-9]+)');
    final urlMatch = urlRefRegex.firstMatch(body);
    final refCode = urlMatch?.group(1) ?? _fallbackRef('CBE');

    return ParsedTransaction(
      name: 'CBE Credit',
      amount: amount,
      balanceAfter: balance,
      transactionType: 'credited',
      referenceCode: refCode,
      paymentLink: _extractUrl(body),
      date: _dateFromMillis(),
    );
  }

  // ===========================================================================
  // BOA PARSER (sender: BOA)
  // ===========================================================================

  ParsedTransaction? _parseBOA() {
    if (_shouldSkipBOA()) return null;

    final parsers = [
      _parseBOADebit,
      _parseBOACredit,
    ];

    for (final parser in parsers) {
      final result = parser();
      if (result != null) return result;
    }

    return null;
  }

  bool _shouldSkipBOA() {
    // Must contain transaction keywords
    final hasTransaction = RegExp(
      r'was (?:debited|credited)',
      caseSensitive: false,
    ).hasMatch(body);

    if (!hasTransaction) return true;

    // Skip token/OTP
    final skipPatterns = [
      r'token\s+number',
      r'\bOTP\b',
      r'Activation\s+Code',
      r'PIN\s+for\s+your\s+Mobile\s+Banking',
      r'KYC\s+has\s+been\s+APPROVED',
    ];

    for (final pattern in skipPatterns) {
      if (body.contains(RegExp(pattern, caseSensitive: false))) return true;
    }

    return false;
  }

  /// BOA DEBIT
  ParsedTransaction? _parseBOADebit() {
    final regex = RegExp(
      r'account\s+[\d*]+\s+was debited with ETB\s+([\d,]+\.?\d*)\.\s*Available Balance:\s*ETB\s+([\d,]+\.?\d*)',
      caseSensitive: false,
      dotAll: true,
    );

    final match = regex.firstMatch(body);
    if (match == null) return null;

    final amount = _parseAmount(match.group(1)!);
    final balance = _parseAmount(match.group(2)!);

    if (amount == null || balance == null) return null;

    // Extract reference from slip URL (not feedback URL)
    final slipRegex = RegExp(r'slip/\?trx=(FT[A-Z0-9]+)');
    final slipMatch = slipRegex.firstMatch(body);
    final refCode = slipMatch?.group(1) ?? _fallbackRef('BOA');

    return ParsedTransaction(
      name: 'BOA Debit',
      amount: amount,
      balanceAfter: balance,
      transactionType: 'debited',
      referenceCode: refCode,
      paymentLink: _extractUrl(body),
      date: _dateFromMillis(),
    );
  }

  /// BOA CREDIT
  ParsedTransaction? _parseBOACredit() {
    final regex = RegExp(
      r'account\s+[\d*]+\s+was credited with ETB\s+([\d,]+\.?\d*)\s+by\s+(.+?)\.\s*Available Balance:\s*ETB\s+([\d,]+\.?\d*)',
      caseSensitive: false,
      dotAll: true,
    );

    final match = regex.firstMatch(body);
    if (match == null) return null;

    final amount = _parseAmount(match.group(1)!);
    final senderName = match.group(2)!.trim();
    final balance = _parseAmount(match.group(3)!);

    if (amount == null || balance == null) return null;

    // Extract reference from slip URL
    final slipRegex = RegExp(r'slip/\?trx=(FT[A-Z0-9]+)');
    final slipMatch = slipRegex.firstMatch(body);
    final refCode = slipMatch?.group(1) ?? _fallbackRef('BOA');

    return ParsedTransaction(
      name: senderName,
      amount: amount,
      balanceAfter: balance,
      transactionType: 'credited',
      referenceCode: refCode,
      paymentLink: _extractUrl(body),
      date: _dateFromMillis(),
    );
  }

  // ===========================================================================
  // AWASH BANK PARSER (sender: Awash Bank) - STUB
  // ===========================================================================

  ParsedTransaction? _parseAwashBank() {
    // No transaction SMS found in current data
    // When implemented, expected format:
    // "Your account XXXX has been debited/credited with ETB X,XXX.XX. Available Balance: ETB X,XXX.XX."
    return null;
  }
}
