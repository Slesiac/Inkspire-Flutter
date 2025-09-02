import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/user_providers.dart';
import '../../repositories/storage_repository.dart';

// Invalidazione dei provider legati a un profilo.
import '../../providers/cache_buster.dart';

class EditMyProfilePage extends ConsumerStatefulWidget {
  const EditMyProfilePage({super.key});

  @override
  ConsumerState<EditMyProfilePage> createState() => _EditMyProfilePageState();
}

class _EditMyProfilePageState extends ConsumerState<EditMyProfilePage> {
  // Bio: ~4 righe * ~40 char = 160 è un buon limite per non sforare visivamente
  static const int _bioMaxChars = 160;

  final _bio = TextEditingController();
  Uint8List? _picked;
  bool _removeImage = false; // permette di rimuovere la foto profilo
  bool _saving = false; // overlay di attesa

  @override
  void dispose() {
    _bio.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final asyncP = ref.watch(myProfileProvider);
    final router = GoRouter.of(context);

    return asyncP.when(
      data: (p) {
        _bio.value = _bio.value.copyWith(text: _bio.text.isEmpty ? (p?.bio ?? '') : _bio.text);

        final avatar = SizedBox(
          width: 120, height: 120,
          child: _picked != null
              ? Image.memory(_picked!, fit: BoxFit.cover)
              : (_removeImage || p?.profilePic == null
                  ? Container(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      child: Icon(Icons.person, size: 72, color: Theme.of(context).colorScheme.onSurfaceVariant),
                    )
                  : CachedNetworkImage(imageUrl: p!.profilePic!, fit: BoxFit.cover)),
        );

        return Scaffold(
          appBar: AppBar(title: const Text('Edit Profile')),
          body: Stack(
            children: [
              // disabilita interazioni durante il salvataggio
              AbsorbPointer(
                absorbing: _saving,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Center(child: ClipOval(child: avatar)),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        OutlinedButton.icon(
                          onPressed: _pick,
                          icon: const Icon(Icons.photo),
                          label: const Text('Change pic'),
                        ),
                        const SizedBox(width: 8),
                        if (_picked != null || (!_removeImage && (p?.profilePic != null)))
                          TextButton.icon(
                            // Tasto "Remove": marca la rimozione e azzera eventuale selezione
                            onPressed: () => setState(() {
                              _picked = null;
                              _removeImage = true; // al Save, profile_pic = null
                            }),
                            icon: const Icon(Icons.delete_outline),
                            label: const Text('Remove'),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _bio,
                      decoration: InputDecoration(
                        labelText: 'Bio',
                        counterText: '${_bio.text.length}/$_bioMaxChars',
                      ),
                      maxLines: 4,
                      maxLength: _bioMaxChars,
                      maxLengthEnforcement: MaxLengthEnforcement.enforced,
                      onChanged: (_) => setState(() {}), // aggiorna il contatore
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      icon: _saving
                          ? const SizedBox(width:16,height:16,child: CircularProgressIndicator(strokeWidth:2))
                          : const Icon(Icons.save),
                      label: const Text('Save'),
                      onPressed: _saving ? null : () async {
                        setState(() => _saving = true);
                        try {
                          // Se _removeImage è true forza null; altrimenti parte dall'URL esistente
                          String? picUrl = _removeImage ? null : p?.profilePic;

                          // Upload nuova immagine se scelta (e sovrascrive picUrl)
                          if (_picked != null) {
                            final storage = StorageRepository();
                            final ts = DateTime.now().millisecondsSinceEpoch;
                            final path = 'avatar_${p?.id ?? 'me'}_$ts.jpg';
                            var url = await storage.uploadPublic(
                              bucket: 'profile-pics',
                              path: path,
                              bytes: _picked!,
                              contentType: 'image/jpeg',
                            );
                            if (url != null) {
                              url = '$url?v=$ts'; // cache buster per evitare vecchia cache
                            }
                            picUrl = url;
                          }

                          await ref.read(userRepositoryProvider).updateMyProfile(
                            bio: _bio.text.trim().isEmpty ? null : _bio.text.trim(),
                            profilePic: picUrl, // se Remove allora null viene salvato
                          );

                          // Helper centralizzato per il profilo corrente.
                          //  - invalidateProfileCaches: invalida userProfileById, userProfileVWById, challengesByUser
                          //  - invalida esplicitamente anche myProfileProvider (helper non lo include).
                          if (p != null) {
                            invalidateProfileCaches(ref, p.id); // helper centrale: profilo "by id" e sue liste/contatori
                          }
                          ref.invalidate(myProfileProvider); // profilo "me" (provider dedicato)
                          
                          // Attesa dei reload principali prima del pop così il ritorno mostra subito l'avatar/bio aggiornati.
                          await Future.wait([
                            if (p != null) ref.read(userProfileByIdProvider(p.id).future),
                            if (p != null) ref.read(userProfileVWByIdProvider(p.id).future),
                            ref.read(myProfileProvider.future),
                          ]);

                          if (!mounted) return;
                          router.pop();
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                          }
                        } finally {
                          if (mounted) setState(() => _saving = false);
                        }
                      },
                    ),
                  ],
                ),
              ),

              // overlay di caricamento
              if (_saving)
                const PositionedFill(),
            ],
          ),
        );
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(appBar: AppBar(), body: Center(child: Text('Error: $e'))),
    );
  }

  Future<void> _pick() async {
    final x = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85, maxWidth: 1024);
    if (x == null) return;
    final bytes = await x.readAsBytes();
    if (!mounted) return;
    setState(() {
      _picked = bytes;
      _removeImage = false; // sta impostando una nuova immagine
    });
  }
}

// Estrae l'overlay in un widget per pulizia
class PositionedFill extends StatelessWidget {
  const PositionedFill({super.key});
  @override
  Widget build(BuildContext context) {
    return const Positioned.fill(
      child: ColoredBox(
        color: Colors.black26,
        child: Center(child: CircularProgressIndicator()),
      ),
    );
  }
}