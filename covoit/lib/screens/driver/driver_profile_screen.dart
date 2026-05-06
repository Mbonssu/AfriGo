import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app_theme.dart';
import '../../data/providers/user_providers.dart';
import '../../widgets/user_avatar.dart';
import '../passenger/chat_screen.dart';
import '../passenger/rating_screen.dart';

class DriverProfileScreen extends ConsumerWidget {
  final String driverId;
  final String driverName;
  final bool isPrime;
  final double rating;
  final int ratingCount;
  final int totalTrips;

  const DriverProfileScreen({
    super.key,
    required this.driverId,
    required this.driverName,
    required this.isPrime,
    this.rating = 0,
    this.ratingCount = 0,
    this.totalTrips = 0,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;

    // Charger les données dynamiques depuis l'API
    final driverAsync = ref.watch(driverProfileProvider(driverId));
    final profileAsync = ref.watch(userProfileProvider(driverId));

    final driverProfile = driverAsync.valueOrNull;
    final userProfile = profileAsync.valueOrNull;

    // Utiliser les données API si disponibles, sinon les paramètres passés
    final displayName = driverProfile?.fullName.isNotEmpty == true
        ? driverProfile!.fullName
        : (userProfile?.fullName ?? driverName);
    final displayIsPrime = driverProfile?.isPrime ?? isPrime;
    final displayRating = driverProfile?.rating ?? (userProfile?.rating ?? rating);
    final displayRatingCount = driverProfile?.ratingCount ?? (userProfile?.totalReviews ?? ratingCount);
    final displayTotalTrips = driverProfile?.totalTrips ?? totalTrips;

    // Utiliser la méthode initials du profil utilisateur si disponible
    String initials = userProfile?.initials ?? '?';
    if (initials == '?' && displayName.isNotEmpty) {
      final parts = displayName
          .split(' ')
          .where((e) => e.isNotEmpty)
          .map((e) => e[0])
          .take(2)
          .join()
          .toUpperCase();
      if (parts.isNotEmpty) {
        initials = parts;
      }
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Header avec photo et infos principales
          SliverAppBar(
            expandedHeight: 240,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: displayIsPrime
                        ? [const Color(0xFFBA7517), AppColors.prime]
                        : [AppColors.green, AppColors.greenDark],
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      PrimeUserAvatar(
                        photoUrl: userProfile?.profilePictureUrl,
                        initials: initials,
                        radius: 48,
                        isPrime: displayIsPrime,
                        backgroundColor: Colors.white.withOpacity(0.25),
                        textColor: Colors.white,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            displayName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (displayIsPrime) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: Colors.white38, width: 1),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.workspace_premium_rounded,
                                      size: 12, color: Colors.white),
                                  SizedBox(width: 4),
                                  Text('PRIME',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800)),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _HeaderStat(
                              label: displayRating > 0 ? displayRating.toStringAsFixed(1) : '-',
                              sublabel: 'Note', icon: Icons.star_rounded),
                          _VertDivider(),
                          _HeaderStat(
                              label: '$displayRatingCount', sublabel: 'Avis', icon: Icons.reviews_rounded),
                          _VertDivider(),
                          _HeaderStat(
                              label: '$displayTotalTrips', sublabel: 'Trajets', icon: Icons.directions_car_rounded),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            title: Text(displayName),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Actions rapides
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChatScreen(
                                  driverName: displayName, isPrime: displayIsPrime),
                            ),
                          ),
                          icon: const Icon(Icons.chat_rounded, size: 18),
                          label: const Text('Contacter'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => RatingScreen(
                                  driverName: displayName, isPrime: displayIsPrime),
                            ),
                          ),
                          icon: const Icon(Icons.star_rounded, size: 18),
                          label: const Text('Évaluer'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Infos véhicule
                  const _SectionTitle('Véhicule'),
                  const SizedBox(height: 10),
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(14),
                      child: Column(
                        children: [
                          _InfoRow(
                            icon: Icons.directions_car_rounded,
                            label: 'Voiture',
                            value: 'Toyota Corolla 2020',
                          ),
                          Divider(height: 16),
                          _InfoRow(
                            icon: Icons.palette_rounded,
                            label: 'Couleur',
                            value: 'Blanc nacré',
                          ),
                          Divider(height: 16),
                          _InfoRow(
                            icon: Icons.airline_seat_recline_normal_rounded,
                            label: 'Places disponibles',
                            value: '4 places',
                          ),
                          Divider(height: 16),
                          _InfoRow(
                            icon: Icons.verified_rounded,
                            label: 'Statut',
                            value: 'Vérifié ✓',
                            valueColor: AppColors.green,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Préférences
                  const _SectionTitle('Préférences à bord'),
                  const SizedBox(height: 10),
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(14),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _PrefChip(icon: Icons.ac_unit_rounded, label: 'Climatisation', ok: true),
                          _PrefChip(icon: Icons.music_note_rounded, label: 'Musique ok', ok: true),
                          _PrefChip(icon: Icons.smoke_free_rounded, label: 'Non-fumeur', ok: true),
                          _PrefChip(icon: Icons.luggage_rounded, label: 'Bagages ok', ok: true),
                          _PrefChip(icon: Icons.pets_rounded, label: 'Animaux', ok: false),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Note détaillée
                  const _SectionTitle('Évaluations'),
                  const SizedBox(height: 10),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Text(
                                displayRating > 0 ? displayRating.toStringAsFixed(1) : '-',
                                style: TextStyle(
                                  fontSize: 48,
                                  fontWeight: FontWeight.w800,
                                  color: cs.onSurface,
                                ),
                              ),
                              const SizedBox(width: 16),
                              const Expanded(
                                child: Column(
                                  children: [
                                    _RatingBar(label: '5', value: 0.78),
                                    _RatingBar(label: '4', value: 0.15),
                                    _RatingBar(label: '3', value: 0.05),
                                    _RatingBar(label: '2', value: 0.01),
                                    _RatingBar(label: '1', value: 0.01),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 20),
                          // Avis récents
                          const _ReviewTile(
                            name: 'Aissatou B.',
                            rating: 5,
                            comment: 'Chauffeur très sympathique, conduite douce et ponctuel !',
                            date: '20 Mars',
                          ),
                          const Divider(height: 16),
                          const _ReviewTile(
                            name: 'Michel T.',
                            rating: 5,
                            comment: 'Parfait comme toujours. Je recommande vivement.',
                            date: '17 Mars',
                          ),
                          const Divider(height: 16),
                          const _ReviewTile(
                            name: 'Caroline N.',
                            rating: 4,
                            comment: 'Bon trajet, climatisation agréable.',
                            date: '14 Mars',
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () {},
                            child: Text('Voir tous les $displayRatingCount avis',
                                style: const TextStyle(color: AppColors.green)),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderStat extends StatelessWidget {
  final String label;
  final String sublabel;
  final IconData icon;

  const _HeaderStat(
      {required this.label, required this.sublabel, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Icon(icon, color: Colors.white70, size: 16),
          const SizedBox(height: 3),
          Text(label,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800)),
          Text(sublabel,
              style: const TextStyle(color: Colors.white60, fontSize: 11)),
        ],
      ),
    );
  }
}

class _VertDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 36, color: Colors.white24);
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.onSurface));
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.green),
        const SizedBox(width: 12),
        Expanded(
            child: Text(label,
                style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant))),
        Text(value,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: valueColor ?? cs.onSurface)),
      ],
    );
  }
}

class _PrefChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool ok;

  const _PrefChip(
      {required this.icon, required this.label, required this.ok});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: ok ? AppColors.greenLight : cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: ok
              ? AppColors.green.withOpacity(0.4)
              : cs.outline.withOpacity(0.4),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon,
              size: 13,
              color: ok ? AppColors.greenDark : cs.onSurfaceVariant),
          const SizedBox(width: 5),
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: ok ? AppColors.greenDark : cs.onSurfaceVariant)),
          if (!ok) ...[
            const SizedBox(width: 4),
            Icon(Icons.close_rounded,
                size: 11, color: cs.onSurfaceVariant),
          ],
        ],
      ),
    );
  }
}

class _RatingBar extends StatelessWidget {
  final String label;
  final double value;

  const _RatingBar({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(label,
              style: const TextStyle(fontSize: 11, color: AppColors.gray600)),
          const SizedBox(width: 6),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: value,
                backgroundColor: AppColors.gray100,
                valueColor:
                    const AlwaysStoppedAnimation(AppColors.prime),
                minHeight: 6,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text('${(value * 100).toInt()}%',
              style: const TextStyle(fontSize: 10, color: AppColors.gray600)),
        ],
      ),
    );
  }
}

class _ReviewTile extends StatelessWidget {
  final String name;
  final int rating;
  final String comment;
  final String date;

  const _ReviewTile({
    required this.name,
    required this.rating,
    required this.comment,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: AppColors.greenLight,
              child: Text(name[0],
                  style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.greenDark)),
            ),
            const SizedBox(width: 8),
            Expanded(
                child: Text(name,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface))),
            Row(
              children: List.generate(
                5,
                (i) => Icon(Icons.star_rounded,
                    size: 12,
                    color: i < rating ? AppColors.prime : cs.outline),
              ),
            ),
            const SizedBox(width: 6),
            Text(date,
                style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
          ],
        ),
        const SizedBox(height: 6),
        Text(comment,
            style: TextStyle(
                fontSize: 12, color: cs.onSurface, height: 1.4)),
      ],
    );
  }
}
