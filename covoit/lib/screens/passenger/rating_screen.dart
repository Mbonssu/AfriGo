import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app_theme.dart';
import '../../data/providers/journey_providers.dart';
import '../../widgets/user_avatar.dart';

class RatingScreen extends ConsumerStatefulWidget {
  final String driverName;
  final String? driverPhotoUrl;
  final bool isPrime;
  final String? bookingId;
  final String? tripSummary;

  const RatingScreen({
    super.key,
    required this.driverName,
    this.driverPhotoUrl,
    required this.isPrime,
    this.bookingId,
    this.tripSummary,
  });

  @override
  ConsumerState<RatingScreen> createState() => _RatingScreenState();
}

class _RatingScreenState extends ConsumerState<RatingScreen> {
  int _rating = 0;
  final _commentCtrl = TextEditingController();
  final List<String> _selectedTags = [];
  bool _isSubmitting = false;

  final List<_TagOption> _positiveTags = const [
    _TagOption(label: 'Ponctuel', icon: Icons.access_time_rounded),
    _TagOption(label: 'Conduite sûre', icon: Icons.security_rounded),
    _TagOption(label: 'Sympathique', icon: Icons.sentiment_very_satisfied_rounded),
    _TagOption(label: 'Véhicule propre', icon: Icons.star_rounded),
    _TagOption(label: 'Bonne musique', icon: Icons.music_note_rounded),
    _TagOption(label: 'Climatisation', icon: Icons.ac_unit_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final initials = widget.driverName.split(' ').map((e) => e[0]).take(2).join();

    return Scaffold(
      appBar: AppBar(title: const Text('Évaluer le trajet')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Driver info
            PrimeUserAvatar(
              photoUrl: widget.driverPhotoUrl,
              initials: initials,
              radius: 40,
              isPrime: widget.isPrime,
            ),
            const SizedBox(height: 12),
            Text(widget.driverName,
                style: TextStyle(
                    
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface)),
            Text(widget.tripSummary ?? '',
                style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
            const SizedBox(height: 28),

            // Stars
            Text('Comment s\'est passé le voyage ?',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface)),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) {
                return GestureDetector(
                  onTap: () => setState(() => _rating = i + 1),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Icon(
                      Icons.star_rounded,
                      size: 44,
                      color: i < _rating ? AppColors.prime : cs.outline,
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 8),
            if (_rating > 0)
              Text(
                _rating == 5
                    ? 'Excellent ! ⭐'
                    : _rating == 4
                        ? 'Très bien 👍'
                        : _rating == 3
                            ? 'Bien 🙂'
                            : _rating == 2
                                ? 'Peut mieux faire 😕'
                                : 'Décevant 😞',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _rating >= 4 ? AppColors.green : AppColors.coral),
              ),

            const SizedBox(height: 24),

            // Tags
            Align(
              alignment: Alignment.centerLeft,
              child: Text('Ce qui s\'est bien passé :',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface)),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _positiveTags.map((tag) {
                final selected = _selectedTags.contains(tag.label);
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (selected) {
                        _selectedTags.remove(tag.label);
                      } else {
                        _selectedTags.add(tag.label);
                      }
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected ? AppColors.greenLight : cs.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: selected ? AppColors.green : cs.outline.withValues(alpha: 0.5),
                        width: selected ? 1.5 : 0.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(tag.icon,
                            size: 14,
                            color: selected ? AppColors.green : cs.onSurfaceVariant),
                        const SizedBox(width: 5),
                        Text(tag.label,
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: selected ? AppColors.greenDark : cs.onSurface)),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 20),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _rating > 0 && _rating <= 2
                    ? 'Commentaire (requis pour note négative) *'
                    : 'Commentaire (optionnel)',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _rating > 0 && _rating <= 2 ? AppColors.coral : cs.onSurface),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _commentCtrl,
              maxLines: 3,
              maxLength: 500,
              decoration: const InputDecoration(
                hintText: 'Partagez votre expérience...',
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _rating > 0 && !_isSubmitting
                    ? () async {
                        final comment = _commentCtrl.text.trim();
                        if (_rating <= 2 && comment.length < 20) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Un commentaire d\'au moins 20 caractères est requis pour une note ≤ 2 étoiles.'),
                            ),
                          );
                          return;
                        }
                        if (widget.bookingId != null) {
                          setState(() => _isSubmitting = true);
                          try {
                            final repo = ref.read(journeyRepositoryProvider);
                            await repo.rateBooking(
                              bookingId: widget.bookingId!,
                              rating: _rating,
                              comment: comment,
                              tags: _selectedTags,
                            );
                            if (mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('✅ Merci pour votre avis !'),
                                  backgroundColor: AppColors.green,
                                ),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Erreur : $e'),
                                  backgroundColor: AppColors.coral,
                                ),
                              );
                            }
                          } finally {
                            if (mounted) setState(() => _isSubmitting = false);
                          }
                        } else {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('⚠️ Évaluation enregistrée localement (connexion indisponible)'),
                              backgroundColor: AppColors.prime,
                            ),
                          );
                        }
                      }
                    : null,
                child: _isSubmitting
                    ? const SizedBox(
                        width: 18, height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Soumettre l\'évaluation'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TagOption {
  final String label;
  final IconData icon;

  const _TagOption({required this.label, required this.icon});
}
