import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../app_theme.dart';
import '../../data/models/app_booking_trip.dart';
import '../../data/providers/journey_providers.dart';
import '../../widgets/user_avatar.dart';
import 'boarding_pass_screen.dart';
import 'chat_screen.dart';
import 'rating_screen.dart';
import '../trip_tracking_screen.dart';

class MyTripsScreen extends ConsumerStatefulWidget {
  const MyTripsScreen({super.key});

  @override
  ConsumerState<MyTripsScreen> createState() => _MyTripsScreenState();
}

class _MyTripsScreenState extends ConsumerState<MyTripsScreen>
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
    final userIdAsync = ref.watch(currentUserIdProvider);
    final userId = userIdAsync.valueOrNull;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes voyages'),
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle:
              const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          tabs: const [
            Tab(text: 'À venir'),
            Tab(text: 'En cours'),
            Tab(text: 'Terminés'),
          ],
        ),
      ),
      body: userId == null || userId.isEmpty
          ? const Center(child: Text('Connectez-vous pour voir vos voyages'))
          : _BookingsBody(tabCtrl: _tabCtrl, passengerId: userId),
    );
  }
}

class _BookingsBody extends ConsumerWidget {
  final TabController tabCtrl;
  final String passengerId;
  const _BookingsBody({required this.tabCtrl, required this.passengerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingsAsync = ref.watch(passengerTripsProvider(passengerId));

    return bookingsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 48, color: AppColors.gray100),
            const SizedBox(height: 12),
            Text('Impossible de charger vos voyages',
                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => ref.invalidate(passengerTripsProvider(passengerId)),
              child: const Text('Réessayer'),
            ),
          ],
        ),
      ),
      data: (bookings) {
        final upcoming = bookings.where((b) => b.effectiveStatus == 'confirmed').toList();
        final ongoing = bookings.where((b) => b.effectiveStatus == 'ongoing').toList();
        final completed = bookings.where((b) =>
            b.effectiveStatus == 'completed' || b.effectiveStatus == 'cancelled').toList();

        return TabBarView(
          controller: tabCtrl,
          children: [
            _TripList(bookings: upcoming),
            _TripList(bookings: ongoing),
            _TripList(bookings: completed),
          ],
        );
      },
    );
  }
}

class _TripList extends StatelessWidget {
  final List<AppBookingTrip> bookings;
  const _TripList({required this.bookings});

  @override
  Widget build(BuildContext context) {
    if (bookings.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.card_travel_rounded,
                size: 56, color: AppColors.gray100),
            SizedBox(height: 16),
            Text('Aucun voyage',
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
      itemCount: bookings.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) => _TripCard(booking: bookings[i]),
    );
  }
}

class _TripCard extends StatelessWidget {
  final AppBookingTrip booking;
  const _TripCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final trip = booking.trip;
    final driver = trip.driver;
    final status = booking.effectiveStatus;
    final initials = driver.fullName
        .split(' ')
        .where((e) => e.isNotEmpty)
        .map((e) => e[0])
        .take(2)
        .join()
        .toUpperCase();

    final dateFmt = DateFormat('dd MMM yyyy', 'fr_FR');
    final timeFmt = DateFormat('HH:mm');
    final dateStr = dateFmt.format(trip.departureTime);
    final timeStr = timeFmt.format(trip.departureTime);

    Color statusColor;
    String statusLabel;
    IconData statusIcon;
    switch (status) {
      case 'confirmed':
        statusColor = AppColors.green;
        statusLabel = 'Confirmé';
        statusIcon = Icons.check_circle_rounded;
        break;
      case 'ongoing':
        statusColor = AppColors.prime;
        statusLabel = 'En cours';
        statusIcon = Icons.directions_car_rounded;
        break;
      case 'completed':
        statusColor = AppColors.gray400;
        statusLabel = 'Terminé';
        statusIcon = Icons.done_all_rounded;
        break;
      default:
        statusColor = AppColors.coral;
        statusLabel = 'Annulé';
        statusIcon = Icons.cancel_rounded;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Route + statut
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
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 11, color: statusColor),
                      const SizedBox(width: 4),
                      Text(statusLabel,
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: statusColor)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.calendar_today_rounded,
                    size: 12, color: cs.onSurfaceVariant),
                const SizedBox(width: 5),
                Text('$dateStr · $timeStr',
                    style: TextStyle(
                        fontSize: 12, color: cs.onSurfaceVariant)),
                const Spacer(),
                Text('${booking.totalPrice} FCFA',
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.green)),
              ],
            ),
            const Divider(height: 16),

            // Chauffeur
            Row(
              children: [
                PrimeUserAvatar(
                  photoUrl: driver.profilePictureUrl,
                  initials: initials,
                  radius: 16,
                  isPrime: driver.isPrime,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(driver.fullName,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: cs.onSurface)),
                      ),
                      if (driver.isPrime) ...[
                        const SizedBox(width: 6),
                        const Icon(Icons.workspace_premium_rounded,
                            size: 14, color: AppColors.prime),
                      ],
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Boutons d'action selon le statut
            if (status == 'confirmed') ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BoardingPassScreen(
                        bookingId: booking.bookingId,
                        tripFrom: trip.from,
                        tripTo: trip.to,
                      ),
                    ),
                  ),
                  icon: const Icon(Icons.qr_code_rounded, size: 15),
                  label: const Text('Carte d\'embarquement'),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      textStyle: const TextStyle(fontSize: 12)),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatScreen(
                            driverName: driver.fullName,
                            isPrime: driver.isPrime,
                            tripConfirmed: true,
                            tripFrom: trip.from,
                            tripTo: trip.to,
                            tripDate: dateStr,
                          ),
                        ),
                      ),
                      icon: const Icon(Icons.chat_rounded, size: 15),
                      label: const Text('Chat'),
                      style: OutlinedButton.styleFrom(
                          padding:
                              const EdgeInsets.symmetric(vertical: 8),
                          textStyle: const TextStyle(fontSize: 12)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          _showCancelDialog(context, driver.fullName, booking.bookingId),
                      icon: const Icon(Icons.cancel_rounded,
                          size: 15, color: AppColors.coral),
                      label: const Text('Annuler'),
                      style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.coral,
                          side: BorderSide(
                              color: AppColors.coral.withOpacity(0.5)),
                          padding:
                              const EdgeInsets.symmetric(vertical: 8),
                          textStyle: const TextStyle(fontSize: 12)),
                    ),
                  ),
                ],
              ),
            ] else if (status == 'ongoing') ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BoardingPassScreen(
                        bookingId: booking.bookingId,
                        tripFrom: trip.from,
                        tripTo: trip.to,
                      ),
                    ),
                  ),
                  icon: const Icon(Icons.qr_code_rounded, size: 15),
                  label: const Text('Carte d\'embarquement'),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      textStyle: const TextStyle(fontSize: 12)),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TripTrackingScreen(
                            from: trip.from,
                            to: trip.to,
                            driverName: driver.fullName,
                            isPrime: driver.isPrime,
                          ),
                        ),
                      ),
                      icon: const Icon(Icons.map_rounded, size: 15),
                      label: const Text('Suivre le trajet'),
                      style: ElevatedButton.styleFrom(
                          padding:
                              const EdgeInsets.symmetric(vertical: 8),
                          textStyle: const TextStyle(fontSize: 12)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatScreen(
                            driverName: driver.fullName,
                            isPrime: driver.isPrime,
                            tripConfirmed: true,
                            tripFrom: trip.from,
                            tripTo: trip.to,
                            tripDate: dateStr,
                          ),
                        ),
                      ),
                      icon: const Icon(Icons.chat_rounded, size: 15),
                      label: const Text('Chat'),
                      style: OutlinedButton.styleFrom(
                          padding:
                              const EdgeInsets.symmetric(vertical: 8),
                          textStyle: const TextStyle(fontSize: 12)),
                    ),
                  ),
                ],
              ),
            ] else if (status == 'completed') ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RatingScreen(
                        driverName: driver.fullName,
                        isPrime: driver.isPrime,
                        bookingId: booking.bookingId,
                        tripSummary: '${trip.from} → ${trip.to} · $dateStr',
                      ),
                    ),
                  ),
                  icon: const Icon(Icons.star_rounded, size: 15),
                  label: const Text('Évaluer le chauffeur'),
                  style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      textStyle: const TextStyle(fontSize: 12)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showCancelDialog(BuildContext context, String driver, String bookingId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Annuler la réservation ?'),
        content: Text(
          'En annulant, votre caution de 500 FCFA sera retenue.\n\nÊtes-vous sûr de vouloir annuler votre voyage avec $driver ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Non, garder'),
          ),
          Consumer(
            builder: (context, ref, _) => ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                try {
                  final repo = ref.read(journeyRepositoryProvider);
                  await repo.cancelBooking(bookingId);
                  ref.invalidate(passengerTripsProvider);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Réservation annulée.'),
                        backgroundColor: AppColors.coral,
                      ),
                    );
                  }
                } catch (_) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Erreur lors de l\'annulation.'),
                        backgroundColor: AppColors.coral,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.coral),
              child: const Text('Oui, annuler'),
            ),
          ),
        ],
      ),
    );
  }
}
