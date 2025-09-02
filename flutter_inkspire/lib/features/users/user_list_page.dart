import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../../providers/user_providers.dart';
import '../../models/user_profile_vw.dart';

class UserListPage extends ConsumerWidget {
  const UserListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncUsers = ref.watch(userListProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: TextField(
            onChanged: (v) => ref.read(userSearchProvider.notifier).state = v,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Search artists',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
        ),
        Expanded(
          child: asyncUsers.when(
            data: (items) => items.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.person_search_outlined,
                              size: 64,
                              color: Theme.of(context).colorScheme.primary),
                          const SizedBox(height: 16),
                          Text(
                            'No artists found',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Try adjusting your search.',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (_, i) => _UserTile(u: items[i]),
                  ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
          ),
        ),
      ],
    );
  }
}

class _UserTile extends StatelessWidget {
  final UserProfileVW u;
  const _UserTile({required this.u});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: _Avatar(url: u.profilePic, fallbackChar: u.username.isNotEmpty ? u.username[0].toUpperCase() : '?'),
      title: Text(u.username),
      subtitle: Text('created: ${u.createdCount} • completed: ${u.completedCount}'),
      onTap: () => context.push('/app/user/${u.id}'),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String? url;
  final String fallbackChar;
  const _Avatar({required this.url, required this.fallbackChar});

  @override
  Widget build(BuildContext context) {
    const size = 40.0;
    return ClipOval(
      child: SizedBox(
        width: size, height: size,
        child: (url == null)
            ? CircleAvatar(child: Text(fallbackChar))
            : CachedNetworkImage(
                imageUrl: url!,
                fit: BoxFit.cover,
                placeholder: (_, __) => const Center(
                  child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                ),
                errorWidget: (_, __, ___) => CircleAvatar(child: Text(fallbackChar)),
              ),
      ),
    );
  }
}