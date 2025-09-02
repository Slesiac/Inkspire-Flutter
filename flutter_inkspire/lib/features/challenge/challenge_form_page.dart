import 'dart:typed_data';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../providers/challenge_providers.dart';
import '../../providers/user_providers.dart';
import '../../repositories/storage_repository.dart';
import '../../models/challenge.dart';

// Helper centralizzati per l'invalidazione cache (senza mettere ref.invalidate(...) in giro)
import '../../providers/cache_buster.dart';

class ChallengeFormPage extends ConsumerStatefulWidget {
  final int? challengeId; // null => add, not null => edit
  const ChallengeFormPage({super.key, this.challengeId});

  @override
  ConsumerState<ChallengeFormPage> createState() => _ChallengeFormPageState();
}

class _ChallengeFormPageState extends ConsumerState<ChallengeFormPage> {
  final _form = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _concept = TextEditingController();
  final _constraint = TextEditingController();
  final _desc = TextEditingController();

  bool _saving = false;
  bool _removeImage = false; // se true => salva result_pic = null
  Uint8List? _pickedBytes; // nuova immagine selezionata
  String? _existingResultPic; // URL già presente
  String? _authorUserId; // owner originale in edit
  bool _initializedFromData = false; // evita di riscrivere i controller

  @override
  void dispose() {
    _title.dispose();
    _concept.dispose();
    _constraint.dispose();
    _desc.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final x = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1600, imageQuality: 85);
    if (x == null) return;
    final bytes = await x.readAsBytes();
    if (!mounted) return;
    setState(() {
      _pickedBytes = bytes;
      _removeImage = false; // sceglie nuova immagine, non sta rimuovendo
    });
  }

  void _removePickedOrExistingImage() {
    setState(() {
      _pickedBytes = null;
      _existingResultPic = null;
      _removeImage = true;
    });
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;

    final router = GoRouter.of(context);
    setState(() { _saving = true; });

    try {
      final repo = ref.read(challengeRepositoryProvider);
      final uid = Supabase.instance.client.auth.currentUser?.id;
      if (uid == null && widget.challengeId == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('You must be logged in to create.')));
        return;
      }

      // Base model (per insert/update)
      // se _removeImage è true allora imposto resultPic: null (rimozione esplicita).
      var model = Challenge(
        id: widget.challengeId ?? 0,
        userProfileId: _authorUserId ?? uid ?? '',
        title: _title.text.trim(),
        concept: _concept.text.trim(),
        artConstraint: _constraint.text.trim(),
        description: _desc.text.trim().isEmpty ? null : _desc.text.trim(),
        resultPic: _removeImage ? null : _existingResultPic,
      );

      int challengeId = widget.challengeId ?? await repo.create(model);
      if (widget.challengeId != null) {
        await repo.update(challengeId, model);
      }

      // Upload immagine se scelta
      if (_pickedBytes != null) {
        final storage = StorageRepository();
        final ts = DateTime.now().millisecondsSinceEpoch;
        final path = 'challenge_${challengeId}_$ts.jpg';
        var url = await storage.uploadPublic(
          bucket: 'challenge-pics',
          path: path,
          bytes: _pickedBytes!,
          contentType: 'image/jpeg',
        );
        if (url != null) {
          url = '$url?v=$ts'; // cache buster per forzare il refresh della cache
          model = model.copyWith(resultPic: url);
          await repo.update(challengeId, model);
        }
      }

      // Invalidazione centralizzata delle cache interessate
      final authorId = _authorUserId ?? uid!;
      invalidateChallengeCaches(ref, challengeId: challengeId);
      invalidateProfileCaches(ref, authorId);

      // Attesa dei reload per rientrare con dati riaggiornati
      await Future.wait([
        ref.read(challengeListVWProvider.future), // Home (lista globale challenges)
        ref.read(challengesByUserProvider(authorId).future), // Lista challenges nel profilo
        ref.read(userProfileVWByIdProvider(authorId).future), // Contatori nel profilo
      ]);

      if (!mounted) return;
      router.pop(); // torna alla pagina precedente (es. View o Home)
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() { _saving = false; });
    }
  }

  Future<void> _deleteChallenge() async {
    if (widget.challengeId == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Challenge'),
        content: const Text('Are you sure you want to delete this challenge?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirm != true) return;

    final router = GoRouter.of(context);
    setState(() { _saving = true; });
    try {
      final repo = ref.read(challengeRepositoryProvider);
      // Prima di cancellare prende l’autore (serve per invalidare il profilo)
      final authorId = _authorUserId ?? Supabase.instance.client.auth.currentUser!.id;

      await repo.delete(widget.challengeId!);
      if (!mounted) return;

      // Invalidazione post-delete
      invalidateChallengeCaches(ref, challengeId: widget.challengeId);
      invalidateProfileCaches(ref, authorId);

      await Future.wait([
        ref.read(challengeListVWProvider.future),
        ref.read(challengesByUserProvider(authorId).future),
        ref.read(userProfileVWByIdProvider(authorId).future),
      ]);

      router.go('/app/home'); // torna alla home
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() { _saving = false; });
    }
  }

  Future<void> _randomConcept() async {
    final repo = ref.read(challengeRepositoryProvider);
    final value = await repo.getRandomConcept();
    if (!mounted) return;
    if (value != null) setState(() => _concept.text = value);
  }

  Future<void> _randomConstraint() async {
    final repo = ref.read(challengeRepositoryProvider);
    final value = await repo.getRandomArtConstraint();
    if (!mounted) return;
    if (value != null) setState(() => _constraint.text = value);
  }

  @override
  Widget build(BuildContext context) {
    // In ADD: nessun fetch, costruisce subito il form
    if (widget.challengeId == null) {
      return _buildScaffold(context, child: _buildForm());
    }

    // In EDIT: carica i dati dalla view (ChallengeVW)
    final asyncC = ref.watch(challengeByIdProvider(widget.challengeId!));
    return asyncC.when(
      data: (c) {
        if (c == null) {
          return const Scaffold(body: Center(child: Text('Challenge not found')));
        }
        // inizializza i controller una sola volta
        if (!_initializedFromData) {
          _title.text = c.title;
          _concept.text = c.concept;
          _constraint.text = c.artConstraint;
          _desc.text = c.description ?? '';
          _existingResultPic = c.resultPic;
          _authorUserId = c.userId;
          _initializedFromData = true;
        }
        return _buildScaffold(context, child: _buildForm(isEdit: true));
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(appBar: AppBar(), body: Center(child: Text('Error: $e'))),
    );
  }

  Widget _buildScaffold(BuildContext context, {required Widget child}) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.challengeId == null ? 'New Challenge' : 'Edit Challenge'),
        actions: [
          if (widget.challengeId != null)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _saving ? null : _deleteChallenge,
              tooltip: 'Delete',
            ),
        ],
      ),
      body: child,
    );
  }

  Widget _buildForm({bool isEdit = false}) {
    final imagePreview = _pickedBytes != null
        ? Image.memory(_pickedBytes!, fit: BoxFit.cover)
        : (_existingResultPic != null
            ? CachedNetworkImage(imageUrl: _existingResultPic!, fit: BoxFit.cover)
            : const SizedBox.shrink());

    return Form(
      key: _form,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_pickedBytes != null || _existingResultPic != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AspectRatio(aspectRatio: 1 / 1, child: imagePreview),
            ),
          const SizedBox(height: 8),
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: _saving ? null : _pickImage,
                icon: const Icon(Icons.photo),
                label: Text((_pickedBytes != null || _existingResultPic != null) ? 'Change pic' : 'Choose pic'),
              ),
              const SizedBox(width: 12),
              if (_pickedBytes != null || _existingResultPic != null)
                TextButton.icon(
                  onPressed: _saving ? null : _removePickedOrExistingImage,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Remove'),
                ),
            ],
          ),

          // Nota informativa su dimensioni e crop
          const SizedBox(height: 8),
          const Text(
            'Recommended size: 1080×1080 (1:1)',
            style: TextStyle(fontSize: 12, color: Colors.black54),
          ),

          const SizedBox(height: 16),

          TextFormField(
            controller: _title,
            decoration: const InputDecoration(labelText: 'Title'),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
          ),
          const SizedBox(height: 12),

          TextFormField(
            controller: _concept,
            decoration: InputDecoration(
              labelText: 'Concept',
              suffixIcon: IconButton(
                onPressed: _saving ? null : _randomConcept,
                icon: const Icon(Icons.shuffle),
                tooltip: 'Suggest concept',
              ),
            ),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
          ),
          const SizedBox(height: 12),

          TextFormField(
            controller: _constraint,
            decoration: InputDecoration(
              labelText: 'Art Constraint',
              suffixIcon: IconButton(
                onPressed: _saving ? null : _randomConstraint,
                icon: const Icon(Icons.shuffle),
                tooltip: 'Suggest constraint',
              ),
            ),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
          ),
          const SizedBox(height: 12),

          TextFormField(
            controller: _desc,
            decoration: const InputDecoration(labelText: 'Description (optional)'),
            maxLines: 5,
          ),
          const SizedBox(height: 24),

          FilledButton.icon(
            icon: _saving
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.check),
            label: Text(isEdit ? 'Save' : 'Create'),
            onPressed: _saving ? null : _save,
          ),
        ],
      ),
    );
  }
}

// Metodo di utilità che permette di creare una nuova istanza di Challenge
// partendo da un’istanza esistente, modificando solo alcuni campi.
extension on Challenge {
  Challenge copyWith({
    int? id,
    String? userProfileId,
    String? title,
    String? concept,
    String? artConstraint,
    String? description,
    String? resultPic,
    DateTime? insertedAt,
    DateTime? updatedAt,
  }) {
    return Challenge(
      id: id ?? this.id,
      userProfileId: userProfileId ?? this.userProfileId,
      title: title ?? this.title,
      concept: concept ?? this.concept,
      artConstraint: artConstraint ?? this.artConstraint,
      description: description ?? this.description,
      resultPic: resultPic ?? this.resultPic,
      insertedAt: insertedAt ?? this.insertedAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}