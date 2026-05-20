



import 'package:flutter/material.dart';

class AppColors {
  // =========================
  // Light Theme Colors
  // =========================
  static const Color bgApp = Color(0xFFF9FAFB);
  static const Color bgCard = Color(0xFFFFFFFF);
  static const Color bgSheet = Color(0xFFF9FAFB);
  
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textMuted = Color(0xFF9CA3AF);
  
  static const Color borderColor = Color(0xFFE5E7EB);
  static const Color bgIcon = Color(0xFFF3F4F6);
  static const Color bgHover = Color(0xFFF9FAFB);

  // Transaction Status (Light)
  static const Color bgReceived = Color(0xFFDCFCE7);
  static const Color textReceived = Color(0xFF16A34A);
  static const Color textReceivedOpacity = Color.fromARGB(255, 158, 240, 188);
  static const Color bgSent = Color.fromARGB(255, 220, 112, 112);
  static const Color textSent = Color(0xFFDC2626);
  static const Color textSentOpacity = Color.fromARGB(255, 247, 146, 146);

  // Header Gradient (Light) - Vibrant Blue -> Purple -> Pink
  static const List<Color> headerGradientLight = [
  // Color.fromARGB(255, 124, 119, 246), // Light Indigo Blue
  Color.fromARGB(255, 109, 101, 155), // Soft Violet
  Color.fromARGB(255, 100, 106, 134), // Light Indigo
  Color.fromARGB(255, 156, 160, 181), // Light Indigo
    
  ];

  // =========================
  // Dark Theme Colors
  // =========================
  static const Color darkBgApp = Color(0xFF111827);
  static const Color darkBgCard = Color(0xFF1F2937);
  static const Color darkBgSheet = Color(0xFF111827);
  
  static const Color darkTextPrimary = Color(0xFFF9FAFB);
  static const Color darkTextSecondary = Color(0xFF9CA3AF);
  static const Color darkTextMuted = Color(0xFF6B7280);
  
  static const Color darkBorderColor = Color(0xFF374151);
  static const Color darkBgIcon = Color.fromARGB(154, 55, 65, 81);
  static const Color darkBgHover = Color(0x2AA3BFEB);

  // Transaction Status (Dark)
  // Note: These use opacity in CSS, closest hex approximation provided or use .withOpacity()
  static const Color darkBgReceived = Color(0x3316A34A); // ~20% opacity Green
  static const Color darkTextReceived = Color(0xFF4ADE80);
  static const Color darkBgSent = Color(0x33DC2626);     // ~20% opacity Red
  static const Color darkTextSent = Color(0xFFF87171);

  // Header Gradient (Dark) - Deep Navy -> Deep Purple -> Indigo
  static const List<Color> headerGradientDark = [
    Color(0xFF1E1B4B), // Indigo 950
    Color(0xFF4C1D95), // Violet 900
    Color(0xFF312E81), // Indigo 900
  ];

  // =========================
  // Brand & UI Colors
  // =========================
  static const Color primaryBrand = Color(0xFF4F46E5); // Indigo 600 (Active Tab)
  
  // Bank Specific Colors
  static const Color bankChase = Color(0xFF2563EB);
  static const Color bankAmerica = Color(0xFFDC2626);
  static const Color bankWellsFargo = Color(0xFFD97706);



  // Banks Gradient
  static const List<Color> awashBankGradient = [Color(0xFF413002), Color(0xFF27231D), Color(0xFF8E7A45)];
  static const List<Color> telebirrBankGradient = [Color(0xFF023841), Color(0xFF022C33), Color(0xDF336B7A)];


}