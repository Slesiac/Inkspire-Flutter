import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/user_providers.dart';
import '../../providers/challenge_providers.dart';
import '../../providers/auth_providers.dart';
import '../../models/user_profile.dart';
import '../../models/user_profile_vw.dart';
import '../../widgets/challenge_card_vw.dart';
import '../../providers/cache_buster.dart';

class UserProfilePage extends ConsumerWidget {
  final String? userId; // null => current user
  final bool showLocalAppBar; // true se la pagina è fuori dalla shell
  const UserProfilePage({super.key, this.userId, this.showLocalAppBar = true});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUid = ref.watch(currentUserIdProvider);
    final targetUid  = userId ?? currentUid;
    final isOwner    = (targetUid != null && currentUid == targetUid);

    final content = targetUid == null
        ? const Center(child: Text('Not authenticated'))
        : _ProfileBody(userId: targetUid, isOwner: isOwner);

    if (!showLocalAppBar) {
      // sotto shell: niente AppBar locale (usa quella della shell)
      return content;
    }

    // fuori shell: AppBar locale con EDIT solo se è il proprio profilo, e LOGOUT con conferma se è il proprio
    return Scaffold(
      appBar: AppBar(
        title: Text(userId == null ? 'My Profile' : "Profile"),
        actions: [
          if (isOwner) ...[
            IconButton(
              icon: const Icon(Icons.edit),
              tooltip: 'Edit profile',
              onPressed: () => GoRouter.of(context).push('/app/profile/edit'),
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Logout',
              onPressed: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Logout'),
                    content: const Text('Are you sure you want to logout?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                      FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Logout')),
                    ],
                  ),
                );
                if (ok != true) return;

                final router = GoRouter.of(context);
                await ref.read(authRepositoryProvider).signOut();
                invalidateAfterAuthChange(ref); // Invalidazione cache vecchia
                if (!context.mounted) return;
                router.go('/login');
              },
            ),
          ],
        ],
      ),
      body: content,
    );
  }
}

class _ProfileBody extends ConsumerWidget {
  final String userId;
  final bool isOwner;
  const _ProfileBody({required this.userId, required this.isOwner});

  static const _avatarSize = 82.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncProfile = ref.watch(userProfileByIdProvider(userId));
    final asyncStats   = ref.watch(userProfileVWByIdProvider(userId));
    final asyncList    = ref.watch(challengesByUserProvider(userId));

    return Column(
      children: [
        // header (avatar + coppia verticale username + bio), layout comune per profilo proprio e altrui
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: asyncProfile.when(
            data: (p) => _Header(profile: p),
            loading: () => const SizedBox(height: _avatarSize, child: Center(child: CircularProgressIndicator())),
            error: (e, _) => Text('Error: $e'),
          ),
        ),

        // stats
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: asyncStats.when(
            data: (vw) => _StatsCentered(vw: vw),
            loading: () => const SizedBox.shrink(),
            error: (e, _) => Text('Error: $e'),
          ),
        ),

        const Divider(height: 16),

        // challenges list (cliccabile)
        Expanded(
          child: asyncList.when(
            data: (items) => items.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.brush_outlined, size: 64, color: Theme.of(context).colorScheme.primary),
                          const SizedBox(height: 16),
                          Text(
                            isOwner
                                ? 'You have not created any challenge yet'
                                : 'This artist has no challenge yet',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            isOwner
                                ? 'Create your first challenge and it will appear here.'
                                : 'Come back later to see their challenges.',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (ctx, i) => ChallengeCardVW(
                      c: items[i],
                      onTap: () => ctx.push('/app/challenge/${items[i].id}'),
                    ),
                  ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
          ),
        ),
      ],
    );
  }
}

// Header con avatar a sinistra e, a destra, coppia verticale "username + bio" (comune a tutti i profili)
// Avatar con spinner di loading e fallback iniziale
class _Header extends StatelessWidget {
  final UserProfile? profile;
  const _Header({required this.profile});

  static const _avatarSize = _ProfileBody._avatarSize;

  @override
  Widget build(BuildContext context) {
    final p = profile;
    final username = (p?.username ?? '').trim().isEmpty ? 'Unknown' : p!.username;
    final bio = (p?.bio ?? '').trim();
    final url = p?.profilePic;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipOval(
          child: SizedBox(
            width: _avatarSize, height: _avatarSize,
            child: (url == null)
                ? Container(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    child: Icon(Icons.person, size: _avatarSize * 0.66, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  )
                : CachedNetworkImage(
                    imageUrl: '${url}?v=${DateTime.now().millisecondsSinceEpoch}',
                    fit: BoxFit.cover,
                    placeholder: (_, __) => const Center(
                      child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)),
                    ),
                    errorWidget: (_, __, ___) => Container(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      child: Icon(Icons.person, size: _avatarSize * 0.66, color: Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                  ),
          ),
        ),
        const SizedBox(width: 16),

        // username + bio (verticale)
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // username
              Text(
                username,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),

              // bio (se presente)
              if (bio.isNotEmpty)
                Text(
                  bio,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatsCentered extends StatelessWidget {
  final UserProfileVW? vw;
  const _StatsCentered({this.vw});

  @override
  Widget build(BuildContext context) {
    if (vw == null) return const SizedBox.shrink();
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _ChipStat(label: 'created', value: vw!.createdCount),
        const SizedBox(width: 8),
        _ChipStat(label: 'completed', value: vw!.completedCount),
      ],
    );
  }
}

class _ChipStat extends StatelessWidget {
  final String label;
  final int value;
  const _ChipStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text('$label: $value'),
      visualDensity: VisualDensity.compact,
    );
  }
}