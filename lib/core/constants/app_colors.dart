import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary palette - Vibrant Blues & Purples
  static const Color primary = Color(0xFF5B7FFF); // Bright Blue
  static const Color primaryLight = Color(0xFF7B9AFF); // Light Blue
  static const Color primaryDark = Color(0xFF4A5FCC); // Deep Blue

  // Accent - Pink/Coral
  static const Color accent = Color(0xFF6C5CE7); // Purple (changed from pink for better versatility)

  // Background & Surface - Light & Airy
  static const Color background = Color(0xFFF7F9FC); // Very Light Blue-Gray
  static const Color surface = Color(0xFFFFFFFF); // Pure White
  static const Color surfaceVariant = Color(0xFFEEF2FF); // Light Purple Tint

  // Text - High Contrast
  static const Color textPrimary = Color(0xFF2D3748); // Dark Gray
  static const Color textSecondary = Color(0xFF718096); // Medium Gray
  static const Color textTertiary = Color(0xFFA0AEC0); // Light Gray

  // Status - Vibrant & Colorful
  static const Color success = Color(0xFF06D6A0); // Bright Teal Green
  static const Color warning = Color(0xFFFFB627); // Bright Orange
  static const Color error = Color(0xFFFF6B9D); // Pink-Red
  static const Color info = Color(0xFF5B7FFF); // Bright Blue

  // Borders & Dividers - Subtle
  static const Color border = Color(0xFFE2E8F0); // Light Gray-Blue
  static const Color divider = Color(0xFFF1F5F9); // Very Light Gray

  // Feature Colors - For Cards & Components
  static const Color purple = Color(0xFF6C5CE7); // Deep Purple - Books/Reading
  static const Color coral = Color(0xFFFF6B6B); // Coral Red - Transactions/Borrows
  static const Color orange = Color(0xFFFFA94D); // Warm Orange - Reservations
  static const Color teal = Color(0xFF20C997); // Teal Green - Libraries
  static const Color yellow = Color(0xFFFFD93D); // Bright Yellow - Stats/Analytics
  static const Color pink = Color(0xFFFF6B9D); // Pink - Accent Actions

  // Badges - Vibrant Status Colors
  static const Color availableBadge = Color(0xFFD1FAE5); // Light Teal
  static const Color availableBadgeText = Color(0xFF065F46); // Dark Teal
  static const Color unavailableBadge = Color(0xFFFFE4E6); // Light Pink
  static const Color unavailableBadgeText = Color(0xFF9F1239); // Dark Pink
  static const Color pendingBadge = Color(0xFFFEF3C7); // Light Yellow
  static const Color pendingBadgeText = Color(0xFF92400E); // Dark Orange

  // ═══════════════════════════════════════════════════════════════════════════
  // DARK MODE COLORS
  // ═══════════════════════════════════════════════════════════════════════════

  // Primary palette - Dark Mode
  static const Color darkPrimary = Color(0xFF7B9AFF); // Lighter Blue for dark bg
  static const Color darkPrimaryLight = Color(0xFF9BB4FF); // Even lighter
  static const Color darkPrimaryDark = Color(0xFF5B7FFF); // Original bright blue

  // Accent - Dark Mode
  static const Color darkAccent = Color(0xFF8B7CE7); // Lighter Purple

  // Background & Surface - Dark Mode
  static const Color darkBackground = Color(0xFF0F1419); // Very Dark Blue-Gray
  static const Color darkSurface = Color(0xFF1A1F2E); // Dark Blue-Gray
  static const Color darkSurfaceVariant = Color(0xFF252B3B); // Lighter Dark

  // Text - Dark Mode
  static const Color darkTextPrimary = Color(0xFFE8EAED); // Light Gray
  static const Color darkTextSecondary = Color(0xFFB0B8C1); // Medium Gray
  static const Color darkTextTertiary = Color(0xFF6B7280); // Darker Gray

  // Status - Dark Mode (slightly adjusted for dark bg)
  static const Color darkSuccess = Color(0xFF10D6A0); // Bright Teal Green
  static const Color darkWarning = Color(0xFFFFBF47); // Brighter Orange
  static const Color darkError = Color(0xFFFF7BA3); // Lighter Pink-Red
  static const Color darkInfo = Color(0xFF7B9AFF); // Lighter Blue

  // Borders & Dividers - Dark Mode
  static const Color darkBorder = Color(0xFF2D3748); // Dark Gray-Blue
  static const Color darkDivider = Color(0xFF1F2937); // Very Dark Gray

  // Feature Colors - Dark Mode (adjusted for visibility)
  static const Color darkPurple = Color(0xFF8B7CE7); // Lighter Purple
  static const Color darkCoral = Color(0xFFFF7B7B); // Lighter Coral
  static const Color darkOrange = Color(0xFFFFB85D); // Lighter Orange
  static const Color darkTeal = Color(0xFF30D9A7); // Lighter Teal
  static const Color darkYellow = Color(0xFFFFE04D); // Lighter Yellow
  static const Color darkPink = Color(0xFFFF7BA3); // Lighter Pink

  // Badges - Dark Mode
  static const Color darkAvailableBadge = Color(0xFF064E3B); // Dark Teal
  static const Color darkAvailableBadgeText = Color(0xFF6EE7B7); // Light Teal
  static const Color darkUnavailableBadge = Color(0xFF881337); // Dark Pink
  static const Color darkUnavailableBadgeText = Color(0xFFFDA4AF); // Light Pink
  static const Color darkPendingBadge = Color(0xFF78350F); // Dark Orange
  static const Color darkPendingBadgeText = Color(0xFFFDE68A); // Light Yellow

  // ═══════════════════════════════════════════════════════════════════════════
  // THEME-AWARE HELPER METHODS
  // ═══════════════════════════════════════════════════════════════════════════

  static Color getBackground(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? darkBackground : background;
  }

  static Color getSurface(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? darkSurface : surface;
  }

  static Color getSurfaceVariant(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? darkSurfaceVariant : surfaceVariant;
  }

  static Color getTextPrimary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? darkTextPrimary : textPrimary;
  }

  static Color getTextSecondary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? darkTextSecondary : textSecondary;
  }

  static Color getTextTertiary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? darkTextTertiary : textTertiary;
  }

  static Color getPrimary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? darkPrimary : primary;
  }

  static Color getPrimaryLight(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? darkPrimaryLight : primaryLight;
  }

  static Color getAccent(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? darkAccent : accent;
  }

  static Color getBorder(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? darkBorder : border;
  }

  static Color getDivider(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? darkDivider : divider;
  }

  static Color getSuccess(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? darkSuccess : success;
  }

  static Color getWarning(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? darkWarning : warning;
  }

  static Color getError(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? darkError : error;
  }

  static Color getInfo(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? darkInfo : info;
  }
}
