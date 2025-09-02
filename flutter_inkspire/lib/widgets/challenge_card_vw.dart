import 'package:flutter/material.dart';
import '../models/challenge_vw.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ChallengeCardVW extends StatelessWidget {
  final ChallengeVW c;
  final VoidCallback? onTap;
  const ChallengeCardVW({super.key, required this.c, this.onTap});

  String _withCacheBuster(String url) {
    try {
      final updatedAt = (c as dynamic).updatedAt as DateTime?;
      if (updatedAt == null) return url;
      final v = updatedAt.millisecondsSinceEpoch;
      return url.contains('?') ? '$url&v=$v' : '$url?v=$v';
    } catch (_) {
      return url;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (c.resultPic != null)
              AspectRatio(
                aspectRatio: 4 / 3,
                child: CachedNetworkImage(
                  imageUrl: _withCacheBuster(c.resultPic!),
                  fit: BoxFit.cover,
                  placeholder: (_, __) => const Center(
                    child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)),
                  ),
                ),
              ),
            ListTile(
              leading: _Avatar(url: c.profilePic, fallbackChar: c.username.isNotEmpty ? c.username[0].toUpperCase() : '?'),
              title: Text(c.title),
              subtitle: Text('${c.concept} • ${c.artConstraint}'),
            ),
          ],
        ),
      ),
    );
  }
}

// Avatar circolare con spinner di loading e fallback iniziale
class _Avatar extends StatelessWidget {
  final String? url;
  final String fallbackChar; //Prima lettera dello username in maiuscolo
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