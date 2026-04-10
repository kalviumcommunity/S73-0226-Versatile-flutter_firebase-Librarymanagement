import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/access_token_model.dart';

/// Admin screen to view all generated access tokens.
class AccessCodesScreen extends StatelessWidget {
  const AccessCodesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final adminUid = context.read<AuthProvider>().userModel?.uid ?? '';
    final tokensRef = FirebaseFirestore.instance
        .collection('access_tokens')
        .where('createdByUid', isEqualTo: adminUid);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Access Codes'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: tokensRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.vpn_key_rounded,
                    size: 56,
                    color: AppColors.textTertiary.withValues(alpha: 0.4),
                  ),
                  const SizedBox(height: AppDimens.md),
                  Text(
                    'No access codes generated yet',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: AppColors.textTertiary),
                  ),
                ],
              ),
            );
          }

          final tokens = snapshot.data!.docs
              .map((doc) => AccessToken.fromJson(doc.data(), doc.id))
              .toList();

          return ListView.separated(
            padding: const EdgeInsets.all(AppDimens.pagePaddingH),
            itemCount: tokens.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppDimens.sm),
            itemBuilder: (context, index) {
              return _TokenCard(token: tokens[index]);
            },
          );
        },
      ),
    );
  }
}

class _TokenCard extends StatelessWidget {
  final AccessToken token;

  const _TokenCard({required this.token});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, yyyy h:mm a');
    final isValid = token.isValid;
    final statusText = token.used
        ? 'Used'
        : token.isExpired
            ? 'Expired'
            : 'Active';
    final statusColor = token.used
        ? AppColors.success
        : token.isExpired
            ? AppColors.error
            : AppColors.warning;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.md),
        child: Row(
          children: [
            // Token icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppDimens.radiusMd),
              ),
              child: Icon(
                token.used
                    ? Icons.check_circle_rounded
                    : token.isExpired
                        ? Icons.timer_off_rounded
                        : Icons.vpn_key_rounded,
                color: statusColor,
                size: 22,
              ),
            ),
            const SizedBox(width: AppDimens.md),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    token.token,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
                      color: isValid ? AppColors.accent : AppColors.textTertiary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Created: ${dateFormat.format(token.createdAt)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (token.used && token.usedByUid != null)
                    Text(
                      'Used by: ${token.usedByUid}',
                      style: Theme.of(context).textTheme.bodySmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),

            // Status
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppDimens.radiusRound),
              ),
              child: Text(
                statusText,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: statusColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
