import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/db/providers.dart';
import '../../../../core/models/downtime_tracking.dart';
import '../../../../core/theme/navigation_theme.dart';
import '../../../../core/theme/hero_sheet_theme.dart';
import '../../../../core/text/heroes_sheet/downtime/followers_tab_text.dart';
import 'follower_editor_dialog.dart';

/// Provider for hero followers
final heroFollowersProvider =
    FutureProvider.family<List<Follower>, String>((ref, heroId) async {
  final repo = ref.read(downtimeRepositoryProvider);
  return await repo.getHeroFollowers(heroId);
});

class FollowersTab extends ConsumerWidget {
  const FollowersTab({super.key, required this.heroId});

  final String heroId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final followersAsync = ref.watch(heroFollowersProvider(heroId));

    return followersAsync.when(
      data: (followers) => _buildContent(context, ref, followers),
      loading: () => const Center(
          child: CircularProgressIndicator(color: HeroSheetTheme.followersAccent)),
      error: (error, stack) => Center(
        child: Text('Error: $error',
            style: TextStyle(color: Colors.grey.shade400)),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    List<Follower> followers,
  ) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: _buildAddButton(context, ref),
        ),
        if (followers.isEmpty)
          SliverFillRemaining(
            child: _buildEmptyState(context, ref),
          )
        else
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => _buildFollowerCard(
                context,
                ref,
                followers[index],
              ),
              childCount: followers.length,
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }

  Widget _buildAddButton(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Material(
        color: NavigationTheme.cardBackgroundDark,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () => _addFollower(context, ref),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: HeroSheetTheme.followersAccent),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.person_add, color: HeroSheetTheme.followersAccent, size: 20),
                SizedBox(width: 8),
                Text(
                  FollowersTabText.addFollowerButtonLabel,
                  style: TextStyle(
                    color: HeroSheetTheme.followersAccent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFollowerCard(
      BuildContext context, WidgetRef ref, Follower follower) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: NavigationTheme.cardBackgroundDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade800),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row: Name, Type, and menu
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: HeroSheetTheme.followersAccent.withAlpha(38),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.person,
                      size: 20, color: HeroSheetTheme.followersAccent),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        follower.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        follower.followerType,
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton(
                  iconSize: 20,
                  iconColor: Colors.grey.shade500,
                  color: NavigationTheme.cardBackgroundDark,
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit,
                              size: 18, color: Colors.grey.shade400),
                          const SizedBox(width: 8),
                          Text(FollowersTabText.editMenuLabel,
                              style: TextStyle(color: Colors.grey.shade300)),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.redAccent, size: 18),
                          SizedBox(width: 8),
                          Text(FollowersTabText.deleteMenuLabel,
                              style: TextStyle(color: Colors.redAccent)),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (value) {
                    if (value == 'edit') {
                      _editFollower(context, ref, follower);
                    } else if (value == 'delete') {
                      _deleteFollower(context, ref, follower);
                    }
                  },
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Characteristics row - all 5 in one compact row
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: NavigationTheme.navBarBackground,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildCharacteristicChip('M', follower.might),
                  _buildCharacteristicChip('A', follower.agility),
                  _buildCharacteristicChip('R', follower.reason),
                  _buildCharacteristicChip('I', follower.intuition),
                  _buildCharacteristicChip('P', follower.presence),
                ],
              ),
            ),

            // Skills section
            if (follower.skills.isNotEmpty) ...[
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.build_outlined,
                      size: 16, color: HeroSheetTheme.followersAccent),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: follower.skills
                          .map((skill) => Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: HeroSheetTheme.followersAccent.withAlpha(38),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  skill,
                                  style: const TextStyle(
                                    color: HeroSheetTheme.followersAccent,
                                    fontSize: 11,
                                  ),
                                ),
                              ))
                          .toList(),
                    ),
                  ),
                ],
              ),
            ],

            // Languages section
            if (follower.languages.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.translate, size: 16, color: Colors.amber.shade600),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: follower.languages
                          .map((lang) => Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.amber.withAlpha(38),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  lang,
                                  style: TextStyle(
                                    color: Colors.amber.shade600,
                                    fontSize: 11,
                                  ),
                                ),
                              ))
                          .toList(),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCharacteristicChip(String label, int value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade500,
            fontWeight: FontWeight.w500,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value.toString(),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: HeroSheetTheme.followersAccent,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey.shade600),
            const SizedBox(height: 16),
            Text(
              FollowersTabText.emptyTitle,
              style: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              FollowersTabText.emptySubtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            Material(
              color: NavigationTheme.cardBackgroundDark,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: () => _addFollower(context, ref),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: HeroSheetTheme.followersAccent),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.person_add, color: HeroSheetTheme.followersAccent, size: 18),
                      SizedBox(width: 8),
                      Text(
                        FollowersTabText.emptyActionLabel,
                        style: TextStyle(
                          color: HeroSheetTheme.followersAccent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addFollower(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<Follower>(
      context: context,
      builder: (context) => FollowerEditorDialog(heroId: heroId),
    );

    if (result != null) {
      final repo = ref.read(downtimeRepositoryProvider);
      await repo.createFollower(
        heroId: heroId,
        name: result.name,
        followerType: result.followerType,
        might: result.might,
        agility: result.agility,
        reason: result.reason,
        intuition: result.intuition,
        presence: result.presence,
        skills: result.skills,
        languages: result.languages,
      );
      ref.invalidate(heroFollowersProvider(heroId));
    }
  }

  void _editFollower(
      BuildContext context, WidgetRef ref, Follower follower) async {
    final result = await showDialog<Follower>(
      context: context,
      builder: (context) => FollowerEditorDialog(
        heroId: heroId,
        existingFollower: follower,
      ),
    );

    if (result != null) {
      final repo = ref.read(downtimeRepositoryProvider);
      await repo.updateFollower(result);
      ref.invalidate(heroFollowersProvider(heroId));
    }
  }

  void _deleteFollower(
      BuildContext context, WidgetRef ref, Follower follower) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(FollowersTabText.deleteDialogTitle),
        content: Text('Remove ${follower.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(FollowersTabText.deleteDialogCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text(FollowersTabText.deleteDialogConfirm),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final repo = ref.read(downtimeRepositoryProvider);
      await repo.deleteFollower(follower.id);
      ref.invalidate(heroFollowersProvider(heroId));
    }
  }
}

