import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/challenge_providers.dart';
import '../../providers/user_providers.dart';

class ViewChallengePage extends ConsumerWidget {
  final int id;
  const ViewChallengePage({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncC = ref.watch(challengeByIdProvider(id));
    final currentUid = ref.watch(currentUserIdProvider);

    return asyncC.when(
      data: (c) {
        if (c == null) return const Scaffold(body: Center(child: Text('Challenge not found')));
        final isAuthor = currentUid == c.userId;

        return Scaffold(
          appBar: AppBar(title: Text(c.title)),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (c.resultPic != null)
                // Frame fisso 1:1 con center-crop (cover) + placeholder
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: AspectRatio(
                    aspectRatio: 1 / 1,
                    child: CachedNetworkImage(
                      imageUrl: _withCacheBuster(c.resultPic!, c.updatedAt),
                      fit: BoxFit.cover, // crop centrale
                      placeholder: (_, __) => const Center(
                        child: SizedBox(width: 32, height: 32, child: CircularProgressIndicator(strokeWidth: 2)),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 12),

              // box autore cliccabile (avatar + username)
              ListTile(
                onTap: () => context.push('/app/user/${c.userId}'),
                leading: _Avatar(url: c.profilePic, fallbackChar: c.username.isNotEmpty ? c.username[0].toUpperCase() : '?', updatedAt: c.updatedAt),
                title: Text(c.username, style: Theme.of(context).textTheme.titleMedium),
                trailing: isAuthor
                    ? FloatingActionButton.small(
                        heroTag: 'edit-challenge-${c.id}',
                        onPressed: () => context.push('/app/challenge/${c.id}/edit'),
                        child: const Icon(Icons.edit),
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(horizontal: 4),
              ),

              const Divider(height: 24),

              ListTile(title: const Text('Concept'), subtitle: Text(c.concept)),
              ListTile(title: const Text('Art constraint'), subtitle: Text(c.artConstraint)),
              if ((c.description ?? '').isNotEmpty)
                ListTile(title: const Text('Description'), subtitle: Text(c.description!)),

              const SizedBox(height: 32), // spazio extra a fine pagina
            ],
          ),
        );
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(appBar: AppBar(), body: Center(child: Text('Error: $e'))),
    );
  }
}

// Helper: aggiunge versione all’URL per forzare refresh immagini aggiornate
String _withCacheBuster(String url, DateTime? updatedAt) {
  final v = (updatedAt ?? DateTime.now()).millisecondsSinceEpoch;
  return url.contains('?') ? '$url&v=$v' : '$url?v=$v';
}

class _Avatar extends StatelessWidget {
  final String? url;
  final String fallbackChar;
  final DateTime? updatedAt;
  const _Avatar({required this.url, required this.fallbackChar, this.updatedAt});

  @override
  Widget build(BuildContext context) {
    const size = 40.0;
    final imgUrl = (url == null) ? null : _withCacheBuster(url!, updatedAt);
    return ClipOval(
      child: SizedBox(
        width: size, height: size,
        child: (imgUrl == null)
            ? CircleAvatar(child: Text(fallbackChar))
            : CachedNetworkImage(
                imageUrl: imgUrl,
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