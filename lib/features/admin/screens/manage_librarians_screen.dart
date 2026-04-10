import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../auth/models/user_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../../library/repository/library_repository.dart';

/// Admin screen to manage all users — promote, demote, or remove.
class ManageLibrariansScreen extends StatefulWidget {
  const ManageLibrariansScreen({super.key});

  @override
  State<ManageLibrariansScreen> createState() => _ManageLibrariansScreenState();
}

class _ManageLibrariansScreenState extends State<ManageLibrariansScreen> {
  final _usersRef = FirebaseFirestore.instance.collection('users');
  final _membersRef = FirebaseFirestore.instance.collection('library_members');
  String _filterRole = 'all';

  @override
  Widget build(BuildContext context) {
    final adminUid = context.read<AuthProvider>().userModel?.uid ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Users'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              children: [
                _FilterChip(
                  label: 'All',
                  selected: _filterRole == 'all',
                  onTap: () => setState(() => _filterRole = 'all'),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Librarians',
                  selected: _filterRole == 'librarian',
                  onTap: () => setState(() => _filterRole = 'librarian'),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Readers',
                  selected: _filterRole == 'member',
                  onTap: () => setState(() => _filterRole = 'member'),
                ),
              ],
            ),
          ),
        ),
      ),
      body: _buildBody(adminUid),
    );
  }

  Widget _buildBody(String adminUid) {
    if (_filterRole == 'librarian') {
      // Show only librarians of this library
      return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _usersRef
            .where('role', isEqualTo: 'librarian')
            .where('libraryId', isEqualTo: adminUid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No librarians found'));
          }

          final users = snapshot.data!.docs
              .map((doc) => UserModel.fromJson(doc.data(), doc.id))
              .toList()
            ..sort((a, b) => a.name.compareTo(b.name));

          return ListView.separated(
            padding: const EdgeInsets.all(AppDimens.pagePaddingH),
            itemCount: users.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppDimens.sm),
            itemBuilder: (context, index) {
              return _UserTile(
                user: users[index],
                adminUid: adminUid,
                onRoleChanged: () => setState(() {}),
              );
            },
          );
        },
      );
    }

    if (_filterRole == 'member') {
      // Show library members (readers who joined this library)
      return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _membersRef
            .where('libraryId', isEqualTo: adminUid)
            .snapshots(),
        builder: (context, memberSnap) {
          if (memberSnap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!memberSnap.hasData || memberSnap.data!.docs.isEmpty) {
            return const Center(child: Text('No members enrolled yet'));
          }
          // Get unique user IDs from memberships
          final memberUserIds = memberSnap.data!.docs
              .map((doc) => doc.data()['userId'] as String?)
              .where((uid) => uid != null)
              .cast<String>()
              .toSet();
          if (memberUserIds.isEmpty) {
            return const Center(child: Text('No members enrolled yet'));
          }
          // Load the actual user docs for these members
          return _buildMembersList(memberUserIds.toList());
        },
      );
    }

    // "All" - show both librarians and members
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _membersRef
          .where('libraryId', isEqualTo: adminUid)
          .snapshots(),
      builder: (context, memberSnap) {
        if (memberSnap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        // Get member user IDs
        final memberUserIds = memberSnap.hasData
            ? memberSnap.data!.docs
                .map((doc) => doc.data()['userId'] as String?)
                .where((uid) => uid != null)
                .cast<String>()
                .toSet()
            : <String>{};

        // Get librarians
        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _usersRef
              .where('role', isEqualTo: 'librarian')
              .where('libraryId', isEqualTo: adminUid)
              .snapshots(),
          builder: (context, librarianSnap) {
            if (librarianSnap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            // Combine both librarians and members
            final allUserIds = <String>{...memberUserIds};
            if (librarianSnap.hasData) {
              allUserIds.addAll(
                librarianSnap.data!.docs.map((doc) => doc.id),
              );
            }

            if (allUserIds.isEmpty) {
              return const Center(child: Text('No users found'));
            }

            return _buildCombinedUsersList(allUserIds.toList());
          },
        );
      },
    );
  }

  Widget _buildMembersList(List<String> userIds) {
    // Firestore whereIn limited to 30
    final chunk = userIds.length > 30 ? userIds.sublist(0, 30) : userIds;
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _usersRef.where(FieldPath.documentId, whereIn: chunk).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No readers found'));
        }
        final users = snapshot.data!.docs
            .map((doc) => UserModel.fromJson(doc.data(), doc.id))
            .where((u) => u.role == 'reader')
            .toList()
          ..sort((a, b) => a.name.compareTo(b.name));
        
        if (users.isEmpty) {
          return const Center(child: Text('No readers found'));
        }

        return ListView.separated(
          padding: const EdgeInsets.all(AppDimens.pagePaddingH),
          itemCount: users.length,
          separatorBuilder: (_, __) => const SizedBox(height: AppDimens.sm),
          itemBuilder: (context, index) {
            return _UserTile(
              user: users[index],
              adminUid: context.read<AuthProvider>().userModel?.uid ?? '',
              onRoleChanged: () => setState(() {}),
            );
          },
        );
      },
    );
  }

  Widget _buildCombinedUsersList(List<String> userIds) {
    // Firestore whereIn limited to 30
    final chunk = userIds.length > 30 ? userIds.sublist(0, 30) : userIds;
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _usersRef.where(FieldPath.documentId, whereIn: chunk).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No users found'));
        }
        final users = snapshot.data!.docs
            .map((doc) => UserModel.fromJson(doc.data(), doc.id))
            .where((u) => u.role != 'admin')
            .toList()
          ..sort((a, b) => a.name.compareTo(b.name));
        
        if (users.isEmpty) {
          return const Center(child: Text('No users found'));
        }

        return ListView.separated(
          padding: const EdgeInsets.all(AppDimens.pagePaddingH),
          itemCount: users.length,
          separatorBuilder: (_, __) => const SizedBox(height: AppDimens.sm),
          itemBuilder: (context, index) {
            return _UserTile(
              user: users[index],
              adminUid: context.read<AuthProvider>().userModel?.uid ?? '',
              onRoleChanged: () => setState(() {}),
            );
          },
        );
      },
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.1)
              : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(AppDimens.radiusRound),
          border: Border.all(
            color:
                selected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? AppColors.primary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _UserTile extends StatelessWidget {
  final UserModel user;
  final String adminUid;
  final VoidCallback onRoleChanged;

  const _UserTile({required this.user, required this.adminUid, required this.onRoleChanged});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDimens.md,
          vertical: AppDimens.xs,
        ),
        leading: CircleAvatar(
          backgroundColor: _roleColor(user.role).withValues(alpha: 0.1),
          backgroundImage:
              user.profilePicUrl != null ? NetworkImage(user.profilePicUrl!) : null,
          child: user.profilePicUrl == null
              ? Text(
                  user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                  style: TextStyle(
                    color: _roleColor(user.role),
                    fontWeight: FontWeight.w700,
                  ),
                )
              : null,
        ),
        title: Text(user.name, style: Theme.of(context).textTheme.titleSmall),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user.email, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: _roleColor(user.role).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppDimens.radiusRound),
              ),
              child: Text(
                user.role.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: _roleColor(user.role),
                ),
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleAction(context, value),
          itemBuilder: (_) => [
            if (user.role == 'reader')
              const PopupMenuItem(
                value: 'promote',
                child: Text('Promote to Librarian'),
              ),
            if (user.role == 'librarian')
              const PopupMenuItem(
                value: 'demote',
                child: Text('Demote to Reader'),
              ),
            const PopupMenuItem(
              value: 'delete',
              child: Text('Remove User', style: TextStyle(color: AppColors.error)),
            ),
          ],
        ),
      ),
    );
  }

  void _handleAction(BuildContext context, String action) async {
    final usersRef = FirebaseFirestore.instance.collection('users');

    if (action == 'promote') {
      // Assign libraryId so the librarian is linked to admin's library
      await usersRef.doc(user.uid).update({
        'role': 'librarian',
        'libraryId': adminUid,
      });
      // Fetch library name to store on user doc
      final library = await LibraryRepository().getLibrary(adminUid);
      if (library != null) {
        await usersRef.doc(user.uid).update({
          'libraryName': library.name,
        });
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${user.name} promoted to Librarian')),
        );
      }
      onRoleChanged();
    } else if (action == 'demote') {
      await usersRef.doc(user.uid).update({
        'role': 'reader',
        'libraryId': FieldValue.delete(),
        'libraryName': FieldValue.delete(),
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${user.name} demoted to Reader')),
        );
      }
      onRoleChanged();
    } else if (action == 'delete') {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Remove User?'),
          content: Text(
              'Remove ${user.name} (${user.email}) from the system? This only deletes the Firestore document.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style:
                  ElevatedButton.styleFrom(backgroundColor: AppColors.error),
              child: const Text('Remove'),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        await usersRef.doc(user.uid).delete();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${user.name} removed')),
          );
        }
        onRoleChanged();
      }
    }
  }

  Color _roleColor(String role) {
    switch (role) {
      case 'admin':
        return AppColors.error;
      case 'librarian':
        return AppColors.accent;
      default:
        return AppColors.success;
    }
  }
}
