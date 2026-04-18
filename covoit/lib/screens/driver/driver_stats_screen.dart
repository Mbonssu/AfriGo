import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app_theme.dart';
import '../../data/models/app_trip.dart';
import '../../data/providers/journey_providers.dart';
import '../../data/providers/user_providers.dart';

class DriverStatsScreen extends ConsumerWidget {
  const DriverStatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final userIdAsync = ref.watch(currentUserIdProvider);
    final userId = userIdAsync.valueOrNull ?? '';

    final tripsAsync = userId.isNotEmpty
        ? ref.watch(driverTripsByIdProvider(userId))
        : const AsyncValue<List<AppTrip>>.data([]);
    final driverAsync = userId.isNotEmpty
        ? ref.watch(driverProfileProvider(userId))
        : null;

    final allTrips = tripsAsync.valueOrNull ?? [];
    final driverProfile = driverAsync?.valueOrNull;

    // Calcul des stats réelles
    final completedTrips =
        allTrips.where((t) => t.status == 'completed').toList();
    final totalRevenue = completedTrips.fold<double>(
        0, (sum, t) => sum + (t.pricePerSeat * t.bookedSeats));
    final avgRating = driverProfile?.rating ?? 0.0;
    final totalTripsCount = allTrips.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes statistiques'),
        actions: [
          if (userId.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: () =>
                  ref.invalidate(driverTripsByIdProvider(userId)),
            ),
        ],
      ),
      body: tripsAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded,
                  size: 40, color: AppColors.coral),
              const SizedBox(height: 8),
              const Text('Erreur de chargement'),
              const SizedBox(height: 8),
              if (userId.isNotEmpty)
                OutlinedButton(
                  onPressed: () =>
                      ref.invalidate(driverTripsByIdProvider(userId)),
                  child: const Text('Réessayer'),
                ),
            ],
          ),
        ),
        data: (_) => SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // Key stats grid
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.5,
              children: [
                _StatCard(
                  label: 'Revenus totaux',
                  value: _formatNumber(totalRevenue),
                  unit: 'FCFA',
                  icon: Icons.account_balance_wallet_rounded,
                  color: AppColors.green,
                ),
                _StatCard(
                  label: 'Trajets effectués',
                  value: '$totalTripsCount',
                  unit: '${completedTrips.length} terminés',
                  icon: Icons.directions_car_rounded,
                  color: AppColors.prime,
                ),
                _StatCard(
                  label: 'Note moyenne',
                  value: avgRating > 0 ? avgRating.toStringAsFixed(1) : '-',
                  unit: '/ 5.0',
                  icon: Icons.star_rounded,
                  color: AppColors.prime,
                ),
                _StatCard(
                  label: 'Places réservées',
                  value: '${allTrips.fold<int>(0, (s, t) => s + t.bookedSeats)}',
                  unit: 'sur ${allTrips.fold<int>(0, (s, t) => s + t.totalSeats)} offertes',
                  icon: Icons.airline_seat_recline_normal_rounded,
                  color: AppColors.green,
                ),
              ],
            ),

            const SizedBox(height: 20),
            Text('Vos trajets récents',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface)),
            const SizedBox(height: 12),

            if (allTrips.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const Icon(Icons.bar_chart_rounded,
                          size: 48, color: AppColors.gray100),
                      const SizedBox(height: 12),
                      Text('Aucune donnée',
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: cs.onSurfaceVariant)),
                      const SizedBox(height: 4),
                      Text('Publiez des trajets pour voir vos stats ici.',
                          style: TextStyle(
                              fontSize: 13,
                              color: cs.onSurfaceVariant)),
                    ],
                  ),
                ),
              )
            else
              ...allTrips.take(5).map((trip) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _TripStatCard(trip: trip),
                  )),

            const SizedBox(height: 32),
          ],
        ),
      ),
      ),
    );
  }

  static String _formatNumber(double value) {
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(value % 1000 == 0 ? 0 : 1)}k';
    }
    return value.toStringAsFixed(0);
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(label,
                    style: TextStyle(
                        fontSize: 11,
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w500)),
                Icon(icon, color: color, size: 18),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    style: TextStyle(
                        
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: color)),
                Text(unit,
                    style: TextStyle(
                        fontSize: 11, color: cs.onSurfaceVariant)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TripStatCard extends StatelessWidget {
  final AppTrip trip;

  const _TripStatCard({required this.trip});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final revenue = trip.pricePerSeat * trip.bookedSeats;
    final statusLabel = switch (trip.status) {
      'completed' => 'Terminé',
      'active' => 'Actif',
      'cancelled' => 'Annulé',
      'in_progress' => 'En cours',
      _ => trip.status,
    };
    final statusColor = switch (trip.status) {
      'completed' => AppColors.green,
      'active' => AppColors.prime,
      'cancelled' => AppColors.coral,
      _ => cs.onSurfaceVariant,
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('${trip.from} → ${trip.to}',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: cs.onSurface)),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(statusLabel,
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: statusColor)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Text(
                    '${trip.bookedSeats}/${trip.totalSeats} places · ${revenue.toStringAsFixed(0)} FCFA',
                    style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

