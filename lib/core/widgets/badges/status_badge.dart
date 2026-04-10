import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_dimens.dart';

enum BadgeType {
  available,
  unavailable,
  pending,
  custom,
}

class StatusBadge extends StatelessWidget {
  final String label;
  final BadgeType type;
  final Color? customColor;
  final Color? customTextColor;

  const StatusBadge({
    super.key,
    required this.label,
    required this.type,
    this.customColor,
    this.customTextColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = _getColors(isDark);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colors.backgroundColor,
            colors.backgroundColor.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppDimens.radiusRound),
        boxShadow: [
          BoxShadow(
            color: colors.textColor.withOpacity(0.15),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: colors.textColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: colors.textColor,
          letterSpacing: 0.6,
        ),
      ),
    );
  }

  _BadgeColors _getColors(bool isDark) {
    switch (type) {
      case BadgeType.available:
        return _BadgeColors(
          backgroundColor: isDark ? AppColors.darkAvailableBadge : AppColors.availableBadge,
          textColor: isDark ? AppColors.darkAvailableBadgeText : AppColors.availableBadgeText,
        );
      case BadgeType.unavailable:
        return _BadgeColors(
          backgroundColor: isDark ? AppColors.darkUnavailableBadge : AppColors.unavailableBadge,
          textColor: isDark ? AppColors.darkUnavailableBadgeText : AppColors.unavailableBadgeText,
        );
      case BadgeType.pending:
        return _BadgeColors(
          backgroundColor: isDark ? AppColors.darkPendingBadge : AppColors.pendingBadge,
          textColor: isDark ? AppColors.darkPendingBadgeText : AppColors.pendingBadgeText,
        );
      case BadgeType.custom:
        return _BadgeColors(
          backgroundColor: customColor ?? (isDark ? AppColors.darkSurfaceVariant : AppColors.surfaceVariant),
          textColor: customTextColor ?? (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
        );
    }
  }
}

class _BadgeColors {
  final Color backgroundColor;
  final Color textColor;

  _BadgeColors({
    required this.backgroundColor,
    required this.textColor,
  });
}
