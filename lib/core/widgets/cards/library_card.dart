import 'package:flutter/material.dart';
import 'package:library_management_app/features/library/models/library_model.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_dimens.dart';
import '../badges/status_badge.dart';

class LibraryCard extends StatelessWidget {
  final LibraryModel library;
  final double? distance;
  final bool isJoined;
  final VoidCallback? onTap;

  const LibraryCard({
    super.key,
    required this.library,
    this.distance,
    required this.isJoined,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.darkTeal : AppColors.teal;
    final primaryColor = isDark ? AppColors.darkPrimary : AppColors.primary;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        gradient: LinearGradient(
          colors: [
            cardColor.withOpacity(0.08),
            primaryColor.withOpacity(0.04),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: cardColor.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: cardColor.withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppDimens.radiusMd),
          child: Padding(
            padding: const EdgeInsets.all(AppDimens.cardPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row with icon, name, and badge
                Row(
                  children: [
                    // Library icon with gradient background
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            cardColor,
                            primaryColor,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                        boxShadow: [
                          BoxShadow(
                            color: cardColor.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.local_library,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: AppDimens.md),
                    // Library name
                    Expanded(
                      child: Text(
                        library.name,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: AppDimens.sm),
                    // Join status badge
                    _buildJoinStatusBadge(),
                  ],
                ),
                const SizedBox(height: AppDimens.sm),
                // Description
                Text(
                  library.description ?? '',
                  style: theme.textTheme.bodyMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppDimens.md),
                // Stats row
                Row(
                  children: [
                    // Member count
                    Icon(
                      Icons.people_outline,
                      size: AppDimens.iconSm,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${library.memberCount} members',
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(width: AppDimens.md),
                    // Book count
                    Icon(
                      Icons.menu_book_outlined,
                      size: AppDimens.iconSm,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${library.bookCount} books',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
                // Distance indicator (conditional)
                if (distance != null) ...[
                  const SizedBox(height: AppDimens.sm),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: AppDimens.iconSm,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${distance!.toStringAsFixed(1)} km away',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildJoinStatusBadge() {
    if (isJoined) {
      return StatusBadge(
        label: 'Joined',
        type: BadgeType.available,
      );
    } else if (library.membershipFee == 0) {
      return StatusBadge(
        label: 'Free',
        type: BadgeType.available,
      );
    } else {
      return StatusBadge(
        label: '\$${library.membershipFee}',
        type: BadgeType.pending,
      );
    }
  }
}
