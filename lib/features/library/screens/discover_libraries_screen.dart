import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/widgets/cards/library_card.dart';
import '../../../core/widgets/empty_states/empty_state_widget.dart';
import '../../../shared/providers/location_provider.dart';
import '../models/library_model.dart';
import '../providers/library_provider.dart';
import 'library_detail_screen.dart';

/// Instagram-style discover screen where readers find and join libraries.
class DiscoverLibrariesScreen extends StatefulWidget {
  const DiscoverLibrariesScreen({super.key});

  @override
  State<DiscoverLibrariesScreen> createState() =>
      _DiscoverLibrariesScreenState();
}

class _DiscoverLibrariesScreenState extends State<DiscoverLibrariesScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    // Request location for distance-based sorting
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LocationProvider>().requestLocation();
    });
  }
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final libraryProvider = context.watch<LibraryProvider>();
    final locationProvider = context.watch<LocationProvider>();
    
    // Get libraries with distance sorting
    List<LibraryModel> allLibraries = libraryProvider.libraries;
    if (locationProvider.userLocation != null) {
      // Update distances and sort by distance
      locationProvider.updateLibraryDistances(allLibraries);
      allLibraries = locationProvider.sortLibrariesByDistance(allLibraries);
    }
    
    final libraries = _searchQuery.isEmpty
        ? allLibraries
        : libraryProvider.searchLibraries(_searchQuery);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Discover Libraries'),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppDimens.pagePaddingH,
              AppDimens.sm,
              AppDimens.pagePaddingH,
              AppDimens.md,
            ),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _searchQuery = v),
                  decoration: InputDecoration(
                    hintText: 'Search libraries...',
                    prefixIcon: const Icon(Icons.search_rounded, size: 22),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 20),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                  ),
                ),
                // Location status
                Consumer<LocationProvider>(
                  builder: (context, locationProvider, child) {
                    if (locationProvider.isLoadingLocation) {
                      return Container(
                        margin: const EdgeInsets.only(top: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'Getting your location...',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      );
                    } else if (locationProvider.error != null) {
                      return Container(
                        margin: const EdgeInsets.only(top: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.location_off, size: 12, color: AppColors.warning),
                            const SizedBox(width: 6),
                            Text(
                              'Sorted alphabetically',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.warning,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      );
                    } else if (locationProvider.userLocation != null) {
                      return Container(
                        margin: const EdgeInsets.only(top: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.location_on, size: 12, color: AppColors.success),
                            const SizedBox(width: 6),
                            const Text(
                              'Sorted by distance',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.success,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ],
            ),
          ),

          // My Libraries section
          if (libraryProvider.memberships.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimens.pagePaddingH,
              ),
              child: Row(
                children: [
                  Text(
                    'My Libraries',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const Spacer(),
                  Text(
                    '${libraryProvider.memberships.length} joined',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimens.sm),
            SizedBox(
              height: 100,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimens.pagePaddingH,
                ),
                itemCount: libraryProvider.memberships.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(width: AppDimens.sm),
                itemBuilder: (context, index) {
                  final membership = libraryProvider.memberships[index];
                  return _JoinedLibraryChip(
                    name: membership.libraryName,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => LibraryDetailScreen(
                          libraryId: membership.libraryId,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: AppDimens.md),
            const Divider(),
          ],

          // All Libraries
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppDimens.pagePaddingH,
              AppDimens.md,
              AppDimens.pagePaddingH,
              AppDimens.sm,
            ),
            child: Row(
              children: [
                Text(
                  _searchQuery.isEmpty ? 'All Libraries' : 'Search Results',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                Text(
                  '${libraries.length} libraries',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),

          Expanded(
            child: libraryProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : libraryProvider.error != null && libraries.isEmpty
                    ? EmptyStateWidget(
                        icon: Icons.error_outline_rounded,
                        title: 'Failed to load libraries',
                        message: 'Please check your connection and try again',
                        actionLabel: 'Retry',
                        onAction: () => libraryProvider.refreshLibraries(),
                      )
                    : libraries.isEmpty
                        ? EmptyStateWidget(
                            icon: Icons.library_books_outlined,
                            title: _searchQuery.isEmpty
                                ? 'No libraries available yet'
                                : 'No libraries match your search',
                            message: _searchQuery.isEmpty
                                ? 'Check back later for new libraries'
                                : 'Try adjusting your search terms',
                            actionLabel: _searchQuery.isEmpty ? 'Refresh' : null,
                            onAction: _searchQuery.isEmpty
                                ? () => libraryProvider.refreshLibraries()
                                : null,
                          )
                        : RefreshIndicator(
                            onRefresh: () async {
                              libraryProvider.refreshLibraries();
                              await Future.delayed(const Duration(seconds: 1));
                            },
                            child: ListView.separated(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppDimens.pagePaddingH,
                                vertical: AppDimens.sm,
                              ),
                              itemCount: libraries.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final lib = libraries[index];
                                return LibraryCard(
                                  library: lib,
                                  distance: lib.distanceFromUser,
                                  isJoined: libraryProvider.isMember(lib.id),
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => LibraryDetailScreen(
                                        libraryId: lib.id,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}

class _JoinedLibraryChip extends StatelessWidget {
  final String name;
  final VoidCallback onTap;

  const _JoinedLibraryChip({required this.name, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 90,
        padding: const EdgeInsets.all(AppDimens.sm),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppDimens.radiusMd),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppDimens.radiusSm),
              ),
              child: const Icon(
                Icons.local_library_rounded,
                color: AppColors.primary,
                size: 22,
              ),
            ),
            const SizedBox(height: AppDimens.xs),
            Text(
              name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
