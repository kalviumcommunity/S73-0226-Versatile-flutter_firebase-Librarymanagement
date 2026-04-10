import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../auth/providers/auth_provider.dart';
import '../../library/providers/library_provider.dart';
import '../../library/models/library_model.dart';
import '../../../shared/services/profile_service.dart';
import '../../../shared/widgets/address_input_widget.dart';
import '../../../shared/providers/location_provider.dart';

/// Admin profile screen with TWO tabs:
/// 1. My Profile — name + profile pic (Instagram-style, same as reader/librarian)
/// 2. Library — library details managed by the admin
class AdminProfileScreen extends StatefulWidget {
  const AdminProfileScreen({super.key});

  @override
  State<AdminProfileScreen> createState() => _AdminProfileScreenState();
}

class _AdminProfileScreenState extends State<AdminProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _profileService = ProfileService();
  bool _isUploadingPic = false;
  File? _pickedImage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ── Image picking ──

  Future<void> _pickImage(ImageSource source) async {
    Navigator.pop(context);
    final file = await _profileService.pickImage(source: source);
    if (file == null || !mounted) return;

    setState(() {
      _pickedImage = file;
      _isUploadingPic = true;
    });

    try {
      final auth = context.read<AuthProvider>();
      final uid = auth.userModel!.uid;
      final url = await _profileService.uploadProfilePic(uid, file);
      await auth.updateProfile({'profilePicUrl': url});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile picture updated!'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.darkError,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingPic = false);
    }
  }

  void _showImagePickerSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.darkBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Change Profile Photo',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.darkPrimary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.camera_alt_rounded,
                      color: AppColors.darkPrimary),
                ),
                title: const Text('Take a Photo'),
                subtitle: const Text('Use your camera'),
                onTap: () => _pickImage(ImageSource.camera),
              ),
              ListTile(
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.photo_library_rounded,
                      color: AppColors.accent),
                ),
                title: const Text('Choose from Gallery'),
                subtitle: const Text('Pick an existing photo'),
                onTap: () => _pickImage(ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Settings ──

  void _showSettingsSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.darkBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Settings',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 8),
              
              _SettingsTile(
                icon: Icons.person_outline_rounded,
                label: 'Edit Profile',
                onTap: () {
                  Navigator.pop(ctx);
                  _showEditNameDialog();
                },
              ),
              _SettingsTile(
                  icon: Icons.business_rounded,
                  label: 'Edit Library Details',
                  onTap: () {
                    Navigator.pop(ctx);
                    _showEditLibraryDialog();
                  },
                ),
                _SettingsTile(
                  icon: Icons.lock_outline_rounded,
                  label: 'Change Password',
                  onTap: () {
                    Navigator.pop(ctx);
                    _showChangePasswordDialog();
                  },
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                _SettingsTile(
                  icon: Icons.logout_rounded,
                  label: 'Sign Out',
                  color: AppColors.darkError,
                  onTap: () {
                    Navigator.pop(ctx);
                    _showSignOutDialog();
                  },
                ),
              ],
            ),
          ),
        ),
    );
  }

  void _showEditNameDialog() {
    final user = context.read<AuthProvider>().userModel;
    final nameCtrl = TextEditingController(text: user?.name ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Edit Name'),
        content: TextField(
          controller: nameCtrl,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            hintText: 'Your name',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimens.radiusMd),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameCtrl.text.trim();
              if (name.isEmpty) return;
              Navigator.pop(ctx);
              await context.read<AuthProvider>().updateProfile({'name': name});
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Name updated!'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showEditLibraryDialog() {
    final user = context.read<AuthProvider>().userModel;
    final nameCtrl = TextEditingController(text: user?.libraryName ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Edit Library Details'),
        content: TextField(
          controller: nameCtrl,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            hintText: 'Library name',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimens.radiusMd),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameCtrl.text.trim();
              if (name.isEmpty) return;
              Navigator.pop(ctx);
              await context
                  .read<AuthProvider>()
                  .updateProfile({'libraryName': name});
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Library details updated!'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog() {
    final auth = context.read<AuthProvider>();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Change Password'),
        content: const Text(
          'We\'ll send a password reset link to your email address.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await auth.sendPasswordResetEmail(
                email: auth.userModel!.email,
              );
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success
                        ? 'Password reset link sent to ${auth.userModel!.email}'
                        : 'Failed to send reset link.'),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor:
                        success ? AppColors.darkSuccess : AppColors.darkError,
                  ),
                );
              }
            },
            child: const Text('Send Link'),
          ),
        ],
      ),
    );
  }

  void _showSignOutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AuthProvider>().signOut();
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.darkError),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  // ── Build ──

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().userModel;
    if (user == null) return const SizedBox.shrink();

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        title: Text(
          user.name,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, size: 24),
            tooltip: 'Settings',
            onPressed: _showSettingsSheet,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.darkPrimary,
          unselectedLabelColor: AppColors.darkTextTertiary,
          indicatorColor: AppColors.darkPrimary,
          indicatorWeight: 2.5,
          tabs: const [
            Tab(text: 'My Profile'),
            Tab(text: 'Library'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildProfileTab(user),
          _buildLibraryTab(user),
        ],
      ),
    );
  }

  // ── Tab 1: My Profile ──

  Widget _buildProfileTab(dynamic user) {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 24),

          // Profile avatar
          _buildProfileAvatar(user.profilePicUrl, user.name),

          const SizedBox(height: 16),

          // Name
          Text(
            user.name,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.darkTextPrimary,
            ),
          ),

          const SizedBox(height: 6),

          // Role badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'ADMIN',
              style: TextStyle(
                color: AppColors.darkError,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.0,
              ),
            ),
          ),

          const SizedBox(height: 28),

          // Stats
          _buildStatsRow(user.email, user.createdAt),

          const SizedBox(height: 28),

          // Actions
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppDimens.pagePaddingH),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _showEditNameDialog,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.darkTextPrimary,
                  side: const BorderSide(color: AppColors.darkBorder),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text(
                  'Edit Name',
                  style:
                      TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
              ),
            ),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ── Tab 2: Library Details ──

  Widget _buildLibraryTab(dynamic user) {
    final libraryName = user.libraryName ?? 'Not set';
    final libraryProvider = context.watch<LibraryProvider>();
    final library = libraryProvider.currentLibrary;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.pagePaddingH),
        child: Column(
          children: [
            const SizedBox(height: 24),

            // Library icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.darkPrimary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.local_library_rounded,
                size: 40,
                color: AppColors.darkPrimary,
              ),
            ),

            const SizedBox(height: 20),

            Text(
              libraryName,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.darkTextPrimary,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 8),

            Text(
              'Managed by ${user.name}',
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.darkTextTertiary,
              ),
            ),

            const SizedBox(height: 32),

            // Library details card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.darkSurface,
                borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                border: Border.all(
                    color: AppColors.darkBorder.withValues(alpha: 0.5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailRow(
                    icon: Icons.business_rounded,
                    label: 'Library Name',
                    value: libraryName,
                  ),
                  const Divider(height: 28),
                  _buildDetailRow(
                    icon: Icons.admin_panel_settings_rounded,
                    label: 'Admin',
                    value: user.name,
                  ),
                  const Divider(height: 28),
                  _buildDetailRow(
                    icon: Icons.email_outlined,
                    label: 'Contact',
                    value: user.email,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Membership Settings
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.darkSurface,
                borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                border: Border.all(
                    color: AppColors.darkBorder.withValues(alpha: 0.5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.card_membership_rounded,
                          color: AppColors.darkPrimary, size: 22),
                      const SizedBox(width: 10),
                      Text(
                        'Membership Settings',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Free Membership',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: AppColors.darkTextPrimary,
                        ),
                      ),
                      Switch(
                        value: library?.isFree ?? true,
                        activeTrackColor: AppColors.darkSuccess,
                        onChanged: (val) => _toggleMembershipType(val),
                      ),
                    ],
                  ),
                  if (library != null && !library.isFree) ...[
                    const Divider(height: 20),
                    _buildDetailRow(
                      icon: Icons.vpn_key_rounded,
                      label: 'Razorpay Key',
                      value: library.razorpayKeyId?.isNotEmpty == true
                          ? '${library.razorpayKeyId!.substring(0, 8)}...'
                          : 'Not set',
                    ),
                    const SizedBox(height: 16),

                    // Plans list
                    if (library.plans.isNotEmpty) ...[
                      const Text(
                        'Membership Plans',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.darkTextSecondary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ...library.plans.asMap().entries.map((entry) {
                        final plan = entry.value;
                        final idx = entry.key;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.darkPrimary.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: AppColors.darkPrimary.withValues(alpha: 0.15),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      plan.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                    Text(
                                      '${plan.durationValue} ${plan.duration} — ₹${plan.price.toStringAsFixed(0)}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.darkTextSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit_rounded, size: 18),
                                onPressed: () => _showAddEditPlanDialog(
                                    editIndex: idx, existing: plan),
                                color: AppColors.darkPrimary,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                    minWidth: 36, minHeight: 36),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded,
                                    size: 18),
                                onPressed: () => _deletePlan(idx),
                                color: AppColors.darkError,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                    minWidth: 36, minHeight: 36),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],

                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _showAddEditPlanDialog(),
                            icon: const Icon(Icons.add_rounded, size: 18),
                            label: const Text(
                              'Add Plan',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.darkPrimary,
                              side: const BorderSide(color: AppColors.darkPrimary),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _showPaymentSettingsDialog,
                            icon: const Icon(Icons.payment_rounded, size: 18),
                            label: const Text(
                              'Razorpay Key',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.accent,
                              side: const BorderSide(color: AppColors.accent),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Address Management
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.darkSurface,
                borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                border: Border.all(
                    color: AppColors.darkBorder.withValues(alpha: 0.5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.location_on_rounded,
                          color: AppColors.darkPrimary, size: 22),
                      const SizedBox(width: 10),
                      Text(
                        'Library Address',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (library?.formattedAddress != null) ...[
                    _buildDetailRow(
                      icon: Icons.place_rounded,
                      label: 'Current Address',
                      value: library!.formattedAddress!,
                    ),
                    const SizedBox(height: 16),
                  ],
                  AddressInputWidget(
                    initialAddress: library?.formattedAddress,
                    onAddressSaved: _onAddressSaved,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _showEditLibraryDialog,
                icon: const Icon(Icons.edit_rounded, size: 18),
                label: const Text(
                  'Edit Library Details',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.darkPrimary,
                  side: const BorderSide(color: AppColors.darkPrimary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  void _toggleMembershipType(bool isFree) async {
    final user = context.read<AuthProvider>().userModel;
    if (user == null) return;
    final libraryId = user.libraryId ?? user.uid;

    // Ensure the library doc exists before updating
    final libProvider = context.read<LibraryProvider>();
    if (libProvider.currentLibrary == null) {
      await libProvider.loadAdminLibrary(
        user.uid,
        adminName: user.name,
        libraryName: user.libraryName ?? user.name,
      );
    }

    if (!isFree) {
      // Switching to paid
      await libProvider.updateLibrary(libraryId, {
        'isFree': false,
      });
      await libProvider.loadAdminLibrary(user.uid);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Switched to paid membership. Add plans below.'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.accent,
          ),
        );
      }
    } else {
      // Switching to free
      await libProvider.updateLibrary(libraryId, {
        'isFree': true,
        'membershipFee': 0,
      });
      await libProvider.loadAdminLibrary(user.uid);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Membership set to free!'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.darkSuccess,
          ),
        );
      }
    }
  }

  void _showAddEditPlanDialog({int? editIndex, MembershipPlan? existing}) {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final priceCtrl = TextEditingController(
      text: existing != null ? existing.price.toStringAsFixed(0) : '',
    );
    final durationValueCtrl = TextEditingController(
      text: existing?.durationValue.toString() ?? '1',
    );
    String selectedDuration = existing?.duration ?? 'monthly';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(editIndex != null ? 'Edit Plan' : 'Add Plan'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: 'Plan Name',
                    hintText: 'e.g. Monthly Plan',
                    prefixIcon: const Icon(Icons.label_rounded, size: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  value: selectedDuration,
                  decoration: InputDecoration(
                    labelText: 'Duration Type',
                    prefixIcon: const Icon(Icons.schedule_rounded, size: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'daily', child: Text('Daily')),
                    DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
                    DropdownMenuItem(value: 'yearly', child: Text('Yearly')),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setDialogState(() => selectedDuration = val);
                    }
                  },
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: durationValueCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Duration Value',
                    hintText: 'e.g. 1, 3, 6',
                    prefixIcon: const Icon(Icons.timelapse_rounded, size: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: priceCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Price (₹)',
                    prefixIcon:
                        const Icon(Icons.currency_rupee_rounded, size: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameCtrl.text.trim();
                final price = double.tryParse(priceCtrl.text.trim()) ?? 0;
                final durationVal =
                    int.tryParse(durationValueCtrl.text.trim()) ?? 1;

                if (name.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a plan name'),
                      backgroundColor: AppColors.darkError,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  return;
                }
                if (price <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a valid price'),
                      backgroundColor: AppColors.darkError,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  return;
                }

                Navigator.pop(ctx);

                final library =
                    context.read<LibraryProvider>().currentLibrary;
                if (library == null) return;

                final newPlan = MembershipPlan(
                  name: name,
                  duration: selectedDuration,
                  durationValue: durationVal,
                  price: price,
                );

                final updatedPlans =
                    List<MembershipPlan>.from(library.plans);
                if (editIndex != null) {
                  updatedPlans[editIndex] = newPlan;
                } else {
                  updatedPlans.add(newPlan);
                }

                final user = context.read<AuthProvider>().userModel;
                final libraryId = user?.libraryId ?? user?.uid ?? '';
                await context.read<LibraryProvider>().updateLibrary(
                  libraryId,
                  {
                    'plans':
                        updatedPlans.map((p) => p.toJson()).toList(),
                    'membershipFee': updatedPlans.first.price,
                  },
                );
                await context
                    .read<LibraryProvider>()
                    .loadAdminLibrary(user!.uid);

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(editIndex != null
                          ? 'Plan updated!'
                          : 'Plan added!'),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: AppColors.darkSuccess,
                    ),
                  );
                }
              },
              child: Text(editIndex != null ? 'Update' : 'Add'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deletePlan(int index) async {
    final library = context.read<LibraryProvider>().currentLibrary;
    if (library == null) return;

    final updatedPlans = List<MembershipPlan>.from(library.plans);
    updatedPlans.removeAt(index);

    final user = context.read<AuthProvider>().userModel;
    final libraryId = user?.libraryId ?? user?.uid ?? '';

    await context.read<LibraryProvider>().updateLibrary(
      libraryId,
      {
        'plans': updatedPlans.map((p) => p.toJson()).toList(),
        'membershipFee':
            updatedPlans.isNotEmpty ? updatedPlans.first.price : 0,
      },
    );
    await context.read<LibraryProvider>().loadAdminLibrary(user!.uid);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Plan removed'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showPaymentSettingsDialog() {
    final library = context.read<LibraryProvider>().currentLibrary;
    final keyCtrl = TextEditingController(
      text: library?.razorpayKeyId ?? '',
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Razorpay Key'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Set your Razorpay API key. Payments will go directly to your Razorpay account.',
              style: TextStyle(fontSize: 13, color: AppColors.darkTextSecondary),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: keyCtrl,
              decoration: InputDecoration(
                labelText: 'Razorpay Key ID',
                helperText: 'Starts with rzp_live_ or rzp_test_',
                prefixIcon: const Icon(Icons.vpn_key_rounded, size: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final key = keyCtrl.text.trim();
              if (key.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter your Razorpay Key ID'),
                    backgroundColor: AppColors.darkError,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                return;
              }
              Navigator.pop(ctx);
              final user = context.read<AuthProvider>().userModel;
              final libraryId = user?.libraryId ?? user?.uid ?? '';
              await context.read<LibraryProvider>().updateLibrary(libraryId, {
                'razorpayKeyId': key,
              });
              await context
                  .read<LibraryProvider>()
                  .loadAdminLibrary(user!.uid);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Razorpay Key saved!'),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: AppColors.darkSuccess,
                  ),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _onAddressSaved(String formattedAddress, double latitude, double longitude) async {
    try {
      final user = context.read<AuthProvider>().userModel;
      if (user == null) return;
      
      final libraryId = user.libraryId ?? user.uid;
      
      // Update library with address and coordinates
      await context.read<LibraryProvider>().updateLibrary(libraryId, {
        'formattedAddress': formattedAddress,
        'latitude': latitude,
        'longitude': longitude,
      });
      
      // Reload library data
      await context.read<LibraryProvider>().loadAdminLibrary(user.uid);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Library address saved successfully!'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.darkSuccess,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save address: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.darkError,
          ),
        );
      }
    }
  }

  // ── Shared widgets ──

  Widget _buildProfileAvatar(String? picUrl, String name) {
    final hasNetworkPic = picUrl != null && picUrl.isNotEmpty;
    final hasLocalPic = _pickedImage != null;

    return GestureDetector(
      onTap: _showImagePickerSheet,
      child: Stack(
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF833AB4),
                  Color(0xFFE1306C),
                  Color(0xFFF77737)
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.darkPrimary.withValues(alpha: 0.2),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(3),
              child: Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.darkBackground,
                ),
                padding: const EdgeInsets.all(2),
                child: ClipOval(
                  child: _isUploadingPic
                      ? Container(
                          color: Colors.black45,
                          child: const Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        )
                      : hasLocalPic
                          ? Image.file(_pickedImage!, fit: BoxFit.cover)
                          : hasNetworkPic
                              ? Image.network(
                                  picUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      _buildInitialsAvatar(name),
                                )
                              : _buildInitialsAvatar(name),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.darkPrimary,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.darkBackground, width: 2),
              ),
              child: const Icon(Icons.add, size: 18, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInitialsAvatar(String name) {
    final initials = name.isNotEmpty
        ? name
            .trim()
            .split(' ')
            .map((e) => e.isEmpty ? '' : e[0])
            .take(2)
            .join()
            .toUpperCase()
        : '?';
    return Container(
      color: AppColors.darkPrimary,
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _buildStatsRow(String email, DateTime createdAt) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimens.pagePaddingH),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.darkSurface,
          borderRadius: BorderRadius.circular(AppDimens.radiusMd),
          border:
              Border.all(color: AppColors.darkBorder.withValues(alpha: 0.5)),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.email_outlined, size: 20, color: AppColors.darkPrimary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    email,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.darkTextPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.calendar_today_outlined, size: 20, color: AppColors.darkPrimary),
                const SizedBox(width: 10),
                Text(
                  'Joined ${_formatDate(createdAt)}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.darkTextPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.darkPrimary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: AppColors.darkPrimary),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.darkTextTertiary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  color: AppColors.darkTextPrimary,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }
}

// ── Private widgets ──

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 18, color: AppColors.darkTextTertiary),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.darkTextTertiary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.darkTextPrimary,
            ),
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _SettingsTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.darkTextPrimary;
    return ListTile(
      leading: Icon(icon, color: c, size: 22),
      title: Text(
        label,
        style: TextStyle(fontWeight: FontWeight.w500, color: c),
      ),
      trailing: Icon(Icons.chevron_right_rounded,
          color: AppColors.darkTextTertiary, size: 20),
      onTap: onTap,
    );
  }
}
