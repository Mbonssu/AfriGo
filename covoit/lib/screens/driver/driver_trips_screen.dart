import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app_theme.dart';
import '../../data/models/app_trip.dart';
import '../../data/providers/journey_providers.dart';
import 'driver_passengers_screen.dart';
import '../trip_tracking_screen.dart';

class DriverTripsScreen extends ConsumerStatefulWidget {
  const DriverTripsScreen({super.key});

  @override
  ConsumerState<DriverTripsScreen> createState() => _DriverTripsScreenState();
}

class _DriverTripsScreenState extends ConsumerState<DriverTripsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tripsAsync = ref.watch(driverTripsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes trajets'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(driverTripsProvider),
          ),
        ],
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle:
              const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          tabs: const [
            Tab(text: 'Actifs'),
            Tab(text: 'En cours'),
            Tab(text: 'Historique'),
          ],
        ),
      ),
      body: tripsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.cloud_off_rounded,
                    size: 56, color: AppColors.gray100),
                const SizedBox(height: 16),
                Text(
                  'Impossible de charger vos trajets',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface),
                ),
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => ref.invalidate(driverTripsProvider),
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: const Text('Réessayer'),
                ),
              ],
            ),
          ),
        ),
        data: (allTrips) {
          final now = DateTime.now();
          
          // À venir: statut active ET départ dans le futur
          final active = allTrips
              .where((t) => 
                  t.status == 'active' && 
                  t.departureTime.isAfter(now))
              .toList();
          
          // En cours: statut active ET départ passé, OU statut ongoing
          final ongoing = allTrips
              .where((t) => 
                  (t.status == 'active' && t.departureTime.isBefore(now)) ||
                  t.status == 'ongoing' || 
                  t.status == 'in_progress')
              .toList();
          
          // Historique: completed ou cancelled
          final history = allTrips
              .where((t) => 
                  t.status == 'completed' || 
                  t.status == 'cancelled')
              .toList();

          return TabBarView(
            controller: _tabCtrl,
            children: [
              _DriverTripList(trips: active),
              _DriverTripList(trips: ongoing),
              _DriverTripList(trips: history),
            ],
          );
        },
      ),
    );
  }
}

class _DriverTripList extends StatelessWidget {
  final List<AppTrip> trips;
  const _DriverTripList({required this.trips});

  @override
  Widget build(BuildContext context) {
    if (trips.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.directions_car_rounded,
                size: 56, color: AppColors.gray100),
            SizedBox(height: 16),
            Text('Aucun trajet',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.gray400)),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: trips.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) => _DriverTripCard(trip: trips[i]),
    );
  }
}

class _DriverTripCard extends ConsumerWidget {
  final AppTrip trip;
  const _DriverTripCard({required this.trip});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final isPrime = trip.driver.isPrime;
    final accent = isPrime ? AppColors.prime : AppColors.green;
    final dateFmt = DateFormat('dd MMM yyyy', 'fr_FR');
    final timeFmt = DateFormat('HH:mm');
    final dateStr = dateFmt.format(trip.departureTime);
    final timeStr = timeFmt.format(trip.departureTime);
    final earnings = trip.pricePerSeat * trip.bookedSeats;

    Color statusColor;
    String statusLabel;
    switch (trip.status) {
      case 'active':
        statusColor = isPrime ? AppColors.prime : AppColors.green;
        statusLabel = isPrime ? 'Actif ✨' : 'Actif';
        break;
      case 'ongoing':
      case 'in_progress':
        statusColor = AppColors.prime;
        statusLabel = 'En route';
        break;
      case 'completed':
        statusColor = AppColors.gray400;
        statusLabel = 'Terminé';
        break;
      default:
        statusColor = AppColors.coral;
        statusLabel = 'Annulé';
    }

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isPrime
              ? AppColors.prime.withValues(alpha: 0.4)
              : const Color(0x1A000000),
          width: isPrime ? 1.5 : 0.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(trip.from,
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: cs.onSurface)),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(Icons.arrow_forward_rounded,
                      size: 16, color: AppColors.green),
                ),
                Text(trip.to,
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: cs.onSurface)),
                const Spacer(),
                _StatusBadge(label: statusLabel, color: statusColor),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.calendar_today_rounded,
                    size: 12, color: cs.onSurfaceVariant),
                const SizedBox(width: 5),
                Text('$dateStr · $timeStr',
                    style: TextStyle(
                        fontSize: 12, color: cs.onSurfaceVariant)),
                const Spacer(),
                Text('$earnings FCFA',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: accent)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text('${trip.bookedSeats}/${trip.totalSeats} passagers',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface)),
                const Spacer(),
                Text(trip.vehicleModel,
                    style: TextStyle(
                        fontSize: 11, color: cs.onSurfaceVariant)),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: trip.totalSeats > 0
                    ? trip.bookedSeats / trip.totalSeats
                    : 0,
                backgroundColor: AppColors.gray100,
                valueColor: AlwaysStoppedAnimation(statusColor),
                minHeight: 5,
              ),
            ),
            const SizedBox(height: 12),

            // Boutons selon statut
            if (trip.status == 'active')
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DriverPassengersScreen(
                            tripId: trip.id,
                            from: trip.from, to: trip.to,
                            date: dateStr, time: timeStr,
                          ),
                        ),
                      ),
                      icon: const Icon(Icons.people_rounded, size: 15),
                      label: const Text('Passagers'),
                      style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          textStyle: const TextStyle(fontSize: 12)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _showStartConfirm(context, trip),
                      icon: const Icon(Icons.play_arrow_rounded, size: 15),
                      label: const Text('Démarrer'),
                      style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          textStyle: const TextStyle(fontSize: 12)),
                    ),
                  ),
                ],
              )
            else if (trip.status == 'ongoing' || trip.status == 'in_progress')
              Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DriverPassengersScreen(
                                tripId: trip.id,
                                from: trip.from, to: trip.to,
                                date: dateStr, time: timeStr,
                              ),
                            ),
                          ),
                          icon: const Icon(Icons.people_rounded, size: 15),
                          label: const Text('Passagers'),
                          style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              textStyle: const TextStyle(fontSize: 12)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => TripTrackingScreen(
                                from: trip.from, to: trip.to,
                                driverName: trip.driver.fullName,
                                isPrime: trip.driver.isPrime,
                                isDriver: true,
                              ),
                            ),
                          ),
                          icon: const Icon(Icons.map_rounded, size: 15),
                          label: const Text('Suivi'),
                          style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              textStyle: const TextStyle(fontSize: 12)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _showCompleteConfirm(context, trip),
                      icon: const Icon(Icons.check_circle_rounded, size: 15),
                      label: const Text('Terminer le trajet'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  void _showStartConfirm(BuildContext context, AppTrip trip) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Démarrer le trajet ?'),
        content: Text(
            'Confirmer le départ ${trip.from} → ${trip.to} avec ${trip.bookedSeats} passager${trip.bookedSeats > 1 ? 's' : ''} ?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TripTrackingScreen(
                    from: trip.from, to: trip.to,
                    driverName: trip.driver.fullName,
                    isPrime: trip.driver.isPrime,
                    isDriver: true,
                  ),
                ),
              );
            },
            child: const Text('Démarrer'),
          ),
        ],
      ),
    );
  }

  void _showCompleteConfirm(BuildContext context, AppTrip trip) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Terminer le trajet ?'),
        content: Text(
            'Marquer le trajet ${trip.from} → ${trip.to} comme terminé ?\n\nTous les passagers ont-ils été déposés ?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _completeTrip(context, trip, ref);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.green,
            ),
            child: const Text('Terminer'),
          ),
        ],
      ),
    );
  }

  Future<void> _completeTrip(BuildContext context, AppTrip trip, WidgetRef ref) async {
    try {
      await ref.read(journeyRepositoryProvider).completeTrip(trip.id);
      ref.invalidate(driverTripsProvider);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Trajet terminé avec succès !'),
            backgroundColor: AppColors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur : $e'),
            backgroundColor: AppColors.coral,
          ),
        );
      }
    }
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 10, fontWeight: FontWeight.w700, color: color)),
    );
  }
}


