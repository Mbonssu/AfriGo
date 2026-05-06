import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app_theme.dart';
import '../../data/models/app_trip_passenger.dart';
import '../../data/providers/journey_providers.dart';
import '../../widgets/user_avatar.dart';
import 'driver_boarding_screen.dart';

class DriverPassengersScreen extends ConsumerWidget {
  final String tripId;
  final String from;
  final String to;
  final String date;
  final String time;

  const DriverPassengersScreen({
    super.key,
    required this.tripId,
    required this.from,
    required this.to,
    required this.date,
    required this.time,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final bookingsAsync = ref.watch(tripBookingsProvider(tripId));

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$from → $to'),
            Text('$date · $time',
                style: const TextStyle(fontSize: 12, color: Colors.white70)),
          ],
        ),
      ),
      body: bookingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded,
                  size: 48, color: AppColors.coral),
              const SizedBox(height: 12),
              const Text('Impossible de charger les passagers'),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () =>
                    ref.invalidate(tripBookingsProvider(tripId)),
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
        data: (passengers) =>
            _PassengersBody(passengers: passengers, cs: cs, tripId: tripId),
      ),
    );
  }
}

class _PassengersBody extends StatelessWidget {
  final List<AppTripPassenger> passengers;
  final ColorScheme cs;
  final String tripId;

  const _PassengersBody({required this.passengers, required this.cs, required this.tripId});

  @override
  Widget build(BuildContext context) {
    if (passengers.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.people_outline_rounded,
                size: 56, color: AppColors.gray100),
            SizedBox(height: 16),
            Text('Aucun passager inscrit',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.gray400)),
          ],
        ),
      );
    }

    final totalSeats = passengers.fold(0, (s, p) => s + p.numberOfSeats);
    final totalEarnings = passengers
        .where((p) => p.isPaid)
        .fold(0, (s, p) => s + p.totalPrice);

    return Column(
      children: [
        Container(
          color: AppColors.green,
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Row(
            children: [
              _SummaryChip(
                  icon: Icons.people_rounded,
                  label:
                      '$totalSeats passager${totalSeats > 1 ? 's' : ''}'),
              const SizedBox(width: 12),
              _SummaryChip(
                  icon: Icons.account_balance_wallet_rounded,
                  label: '$totalEarnings FCFA'),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: passengers.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) =>
                _PassengerCard(passenger: passengers[i], tripId: tripId),
          ),
        ),
      ],
    );
  }
}

class _PassengerCard extends ConsumerWidget {
  final AppTripPassenger passenger;
  final String tripId;

  const _PassengerCard({required this.passenger, required this.tripId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;

    String statusLabel;
    Color statusColor;
    switch (passenger.status) {
      case 'confirmed':
        statusLabel = 'Confirmé';
        statusColor = AppColors.green;
        break;
      case 'accepted':
        statusLabel = 'Accepté';
        statusColor = AppColors.green;
        break;
      case 'rejected':
        statusLabel = 'Refusé';
        statusColor = AppColors.coral;
        break;
      case 'completed':
        statusLabel = 'Terminé';
        statusColor = AppColors.gray400;
        break;
      case 'cancelled':
        statusLabel = 'Annulé';
        statusColor = AppColors.coral;
        break;
      case 'no_show':
        statusLabel = 'Absent';
        statusColor = AppColors.coral;
        break;
      default:
        statusLabel = 'En attente';
        statusColor = AppColors.prime;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                UserAvatar(
                  photoUrl: passenger.photoUrl,
                  initials: passenger.initials,
                  radius: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(passenger.displayName,
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: cs.onSurface)),
                      if (passenger.phone.isNotEmpty)
                        Text(passenger.phone,
                            style: TextStyle(
                                fontSize: 12,
                                color: cs.onSurfaceVariant)),
                      Text(
                          '${passenger.numberOfSeats} place${passenger.numberOfSeats > 1 ? 's' : ''} · ${passenger.totalPrice} FCFA',
                          style: TextStyle(
                              fontSize: 12, color: cs.onSurfaceVariant)),
                    ],
                  ),
                ),
                _StatusBadge(label: statusLabel, color: statusColor),
              ],
            ),
            // Boutons Accepter / Refuser pour passagers en attente
            if (passenger.status == 'pending') ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _acceptBooking(context, ref),
                      icon: const Icon(Icons.check_rounded, size: 16),
                      label: const Text('Accepter'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _rejectBooking(context, ref),
                      icon: const Icon(Icons.close_rounded, size: 16),
                      label: const Text('Refuser'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.coral,
                        side: const BorderSide(color: AppColors.coral),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ],
            // Bouton embarquement pour passagers confirmés
            if (passenger.status == 'confirmed' && !passenger.isBoarded) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final result = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DriverBoardingVerifyScreen(
                          bookingId: passenger.bookingId,
                          passengerName: passenger.displayName,
                        ),
                      ),
                    );
                    if (result == true && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${passenger.displayName} embarqué !'),
                          backgroundColor: AppColors.green,
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.qr_code_scanner_rounded, size: 16),
                  label: const Text('Vérifier l\'embarquement'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
            if (passenger.isBoarded) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                decoration: BoxDecoration(
                  color: AppColors.greenLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_circle_rounded, size: 16, color: AppColors.green),
                    const SizedBox(width: 6),
                    Text(
                      'Embarqué${passenger.boardingMethod != null ? ' (${passenger.boardingMethod == "qr" ? "QR" : "PIN"})' : ''}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.green,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (passenger.pickupLocation != null &&
                passenger.pickupLocation!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.location_on_rounded,
                        size: 14, color: AppColors.green),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Point de prise en charge : ${passenger.pickupLocation}',
                        style: TextStyle(
                            fontSize: 12, color: cs.onSurfaceVariant),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _acceptBooking(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(journeyRepositoryProvider).acceptBooking(passenger.bookingId);
      ref.invalidate(tripBookingsProvider(tripId));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${passenger.displayName} accepté !'),
            backgroundColor: AppColors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e'), backgroundColor: AppColors.coral),
        );
      }
    }
  }

  Future<void> _rejectBooking(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Refuser ce passager ?'),
        content: Text('${passenger.displayName} (${passenger.numberOfSeats} place${passenger.numberOfSeats > 1 ? 's' : ''}) sera refusé.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Non')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Oui, refuser', style: TextStyle(color: AppColors.coral)),
          ),
        ],
      ),
    );
    if (confirm != true || !context.mounted) return;

    try {
      await ref.read(journeyRepositoryProvider).rejectBooking(passenger.bookingId);
      ref.invalidate(tripBookingsProvider(tripId));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${passenger.displayName} refusé.'),
            backgroundColor: AppColors.coral,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e'), backgroundColor: AppColors.coral),
        );
      }
    }
  }
}

class _SummaryChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SummaryChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.white70),
        const SizedBox(width: 5),
        Text(label,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500)),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
