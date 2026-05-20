import 'package:intl/intl.dart';

/// Utility class for formatting values
class Formatters {
  /// Format currency with commas and 2 decimal places
  /// Example: 1234567.89 -> 1,234,567.89
  static String formatCurrency(double amount) {
    final formatter = NumberFormat('#,##0.00', 'en_US');
    return formatter.format(amount);
  }

  /// Format currency without decimal places for whole numbers
  /// Example: 1234567.00 -> 1,234,567
  static String formatCurrencyCompact(double amount) {
    if (amount == amount.roundToDouble()) {
      final formatter = NumberFormat('#,##0', 'en_US');
      return formatter.format(amount);
    }
    return formatCurrency(amount);
  }

  /// Format date to readable format
  /// Example: 2026-03-15 14:30:00 -> Mar 15, 2026 2:30 PM
  static String formatDateTime(DateTime date) {
    return DateFormat('MMM dd, yyyy h:mm a').format(date);
  }

  /// Format date only
  /// Example: 2026-03-15 -> Mar 15, 2026
  static String formatDate(DateTime date) {
    return DateFormat('MMM dd, yyyy').format(date);
  }

  /// Format phone number for display
  /// Example: 251953511050 -> +251 95 351 1050
  static String formatPhoneNumber(String phone) {
    if (phone.length < 10) return phone;
    
    // Remove any non-digit characters
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    
    if (digits.length == 12 && digits.startsWith('251')) {
      return '+251 ${digits.substring(3, 5)} ${digits.substring(5, 8)} ${digits.substring(8)}';
    }
    
    return phone;
  }
}
