import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app_theme.dart';
import '../../core/constants/api_endpoints.dart';
import '../../data/models/app_trip.dart';
import '../../data/providers/vehicle_providers.dart';
import '../../features/trip/widgets/waypoint_display.dart';
import '../driver/driver_profile_screen.dart';
import '../payment/payment_screen.dart';
import 'chat_screen.dart';
import 'rating_screen.dart';

class TripDetailScreen extends ConsumerWidget {
  final AppTrip trip;
  final bool alreadyBooked;

  const TripDetailScreen({
    super.key,
    required this.trip,
    this.alreadyBooked = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final driver = trip.driver;
    final durationMinutes = AppTrip.estimateDurationMinutes(trip.from, trip.to);
    final departureTime = DateFormat('HH:mm').format(trip.departureTime);
    final arrivalTime = DateFormat('HH:mm')
        .format(trip.departureTime.add(Duration(minutes: durationMinutes)));
    final durationLabel = _formatDuration(durationMinutes);
    final initials = driver.fullName
        .split(' ')
        .where((part) => part.isNotEmpty)
        .map((part) => part[0])
        .take(2)
        .join();
    final comfortOptions = trip.comfortOptions.isEmpty
        ? const ['Trajet standard']
        : trip.comfortOptions;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Détail du trajet'),
        actions: [
          IconButton(icon: const Icon(Icons.share_rounded), onPressed: () {}),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              color: AppColors.green,
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Column(
                    children: [
                      Text(
                        departureTime,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        trip.from,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.white70,
                          size: 20,
                        ),
                        Text(
                          '~$durationLabel',
                          style: TextStyle(color: Colors.white60, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        arrivalTime,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        trip.to,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Votre chauffeur',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 12),
                          GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => DriverProfileScreen(
                                  driverId: driver.userId,
                                  driverName: driver.fullName,
                                  isPrime: driver.isPrime,
                                  rating: driver.rating,
                                  ratingCount: driver.ratingCount,
                                  totalTrips: driver.totalTrips,
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 28,
                                  backgroundColor: driver.isPrime
                                      ? AppColors.primeBg
                                      : AppColors.greenLight,
                                  child: Text(
                                    initials,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: driver.isPrime
                                          ? AppColors.primeDark
                                          : AppColors.greenDark,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Flexible(
                                            child: Text(
                                              driver.fullName,
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w700,
                                                color: cs.onSurface,
                                              ),
                                            ),
                                          ),
                                          if (driver.isPrime) ...[
                                            const SizedBox(width: 8),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 7,
                                                vertical: 3,
                                              ),
                                              decoration: BoxDecoration(
                                                color: AppColors.primeBg,
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                              ),
                                              child: const Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    Icons
                                                        .workspace_premium_rounded,
                                                    size: 11,
                                                    color: AppColors.prime,
                                                  ),
                                                  SizedBox(width: 3),
                                                  Text(
                                                    'PRIME',
                                                    style: TextStyle(
                                                      fontSize: 9,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color:
                                                          AppColors.primeDark,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      if (driver.rating > 0)
                                        Row(
                                          children: [
                                            ...List.generate(
                                              5,
                                              (index) => Icon(
                                                Icons.star_rounded,
                                                size: 14,
                                                color: index <
                                                        driver.rating.floor()
                                                    ? AppColors.prime
                                                    : cs.outline,
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              '${driver.rating.toStringAsFixed(1)} · ${driver.ratingCount} avis',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: cs.onSurfaceVariant,
                                              ),
                                            ),
                                          ],
                                        )
                                      else
                                        Text(
                                          'Nouveau chauffeur',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: cs.onSurfaceVariant,
                                          ),
                                        ),
                                      Text(
                                        '${driver.totalTrips} trajets effectués',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: cs.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.chevron_right_rounded,
                                  color: cs.onSurfaceVariant,
                                ),
                              ],
                            ),
                          ),
                          const Divider(height: 20),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _InfoPill(
                                icon: Icons.directions_car_rounded,
                                label: trip.vehicleModel,
                              ),
                              _InfoPill(
                                icon: Icons.pin_outlined,
                                label: trip.vehiclePlate,
                              ),
                              ...comfortOptions.take(2).map(
                                    (item) => _InfoPill(
                                      icon: Icons.check_circle_outline_rounded,
                                      label: item,
                                    ),
                                  ),
                            ],
                          ),
                          // Vehicle photos
                          if (trip.vehicleId != null && trip.vehicleId!.isNotEmpty)
                            _VehiclePhotosCarousel(
                              userId: trip.driverId,
                              vehicleId: trip.vehicleId!,
                            ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: alreadyBooked
                                      ? () => Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => ChatScreen(
                                                driverName: driver.fullName,
                                                isPrime: driver.isPrime,
                                                tripConfirmed: true,
                                              ),
                                            ),
                                          )
                                      : () => _showChatLockedSnack(context),
                                  icon: Icon(
                                    Icons.chat_rounded,
                                    size: 16,
                                    color: alreadyBooked
                                        ? AppColors.green
                                        : AppColors.gray400,
                                  ),
                                  label: Text(
                                    alreadyBooked
                                        ? 'Contacter'
                                        : 'Chat (réserver)',
                                    style: TextStyle(
                                      color: alreadyBooked
                                          ? AppColors.green
                                          : AppColors.gray400,
                                    ),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 10),
                                    side: BorderSide(
                                      color: alreadyBooked
                                          ? AppColors.green
                                          : AppColors.gray100,
                                    ),
                                    textStyle: const TextStyle(fontSize: 13),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => RatingScreen(
                                        driverName: driver.fullName,
                                        isPrime: driver.isPrime,
                                      ),
                                    ),
                                  ),
                                  icon:
                                      const Icon(Icons.star_rounded, size: 16),
                                  label: const Text('Évaluer'),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 10),
                                    textStyle: const TextStyle(fontSize: 13),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Affichage des points de ramassage
                  if (trip.waypoints.isNotEmpty)
                    WaypointDisplay(
                      waypoints: trip.waypoints,
                      departureCity: trip.from,
                      arrivalCity: trip.to,
                      departureTime: trip.departureTime,
                    ),
                  
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Détails de la réservation',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _DetailRow(
                            icon: Icons.airline_seat_recline_normal_rounded,
                            label: 'Places disponibles',
                            value:
                                '${trip.availableSeats} place${trip.availableSeats > 1 ? 's' : ''}',
                          ),
                          const Divider(height: 16),
                          const _DetailRow(
                            icon: Icons.phone_android_rounded,
                            label: 'Paiement',
                            value: 'MTN / Orange Money via Monetbil',
                          ),
                          const Divider(height: 16),
                          const _DetailRow(
                            icon: Icons.security_rounded,
                            label: 'Caution passager',
                            value: '500 FCFA',
                          ),
                          const Divider(height: 16),
                          _DetailRow(
                            icon: Icons.luggage_rounded,
                            label: 'Confort',
                            value: comfortOptions.take(2).join(' · '),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.coralLight,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.coral.withValues(alpha: 0.3),
                        width: 0.5,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.warning_rounded,
                          color: AppColors.coral,
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Politique d\'annulation',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.coral,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'La caution de 500 FCFA est remboursée si le chauffeur annule. En cas d\'annulation de votre part, elle reste acquise.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color:
                                      AppColors.coral.withValues(alpha: 0.85),
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cs.surface,
          border: Border(
            top: BorderSide(
                color: cs.outline.withValues(alpha: 0.3), width: 0.5),
          ),
        ),
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${trip.pricePerSeat} FCFA',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.green,
                  ),
                ),
                Text(
                  '+ 500 FCFA de caution',
                  style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed:
                    trip.isBookable ? () => _showBookingSheet(context) : null,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(
                  trip.isBookable
                      ? 'Réserver maintenant'
                      : 'Trajet indisponible',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showChatLockedSnack(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Le chat est disponible uniquement après avoir réservé ce trajet.',
        ),
        backgroundColor: AppColors.gray600,
      ),
    );
  }

  void _showBookingSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _BookingSheet(trip: trip),
    );
  }
}

class _BookingSheet extends StatefulWidget {
  final AppTrip trip;

  const _BookingSheet({required this.trip});

  @override
  State<_BookingSheet> createState() => _BookingSheetState();
}

class _BookingSheetState extends State<_BookingSheet> {
  String _payMethod = 'mtn';
  int _nbSeats = 1;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final total = widget.trip.pricePerSeat * _nbSeats + 500;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: cs.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Confirmer la réservation',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Nombre de places',
                style: TextStyle(fontSize: 14, color: cs.onSurface),
              ),
              Row(
                children: [
                  IconButton(
                    onPressed:
                        _nbSeats > 1 ? () => setState(() => _nbSeats--) : null,
                    icon: const Icon(Icons.remove_circle_outline_rounded),
                    iconSize: 22,
                  ),
                  Text(
                    '$_nbSeats',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                    ),
                  ),
                  IconButton(
                    onPressed: _nbSeats < widget.trip.availableSeats
                        ? () => setState(() => _nbSeats++)
                        : null,
                    icon: const Icon(Icons.add_circle_outline_rounded),
                    iconSize: 22,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Mode de paiement',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 10),
          _PayTile(
            label: 'MTN Mobile Money',
            logo: '🟡',
            selected: _payMethod == 'mtn',
            onTap: () => setState(() => _payMethod = 'mtn'),
          ),
          const SizedBox(height: 8),
          _PayTile(
            label: 'Orange Money',
            logo: '🟠',
            selected: _payMethod == 'orange',
            onTap: () => setState(() => _payMethod = 'orange'),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.greenLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${widget.trip.pricePerSeat} FCFA × $_nbSeats place${_nbSeats > 1 ? 's' : ''}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.greenDark,
                      ),
                    ),
                    const Text(
                      '+ 500 FCFA de caution',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.greenDark,
                      ),
                    ),
                  ],
                ),
                Text(
                  '$total FCFA',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.green,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PaymentScreen(
                      amount: total.toString(),
                      description:
                          'Réservation ${widget.trip.driver.fullName} · $_nbSeats place${_nbSeats > 1 ? 's' : ''}',
                      paymentType: 'booking',
                      tripId: widget.trip.id,
                      seatCount: _nbSeats,
                      initialMethod: _payMethod,
                    ),
                  ),
                );
              },
              child: Text('Payer $total FCFA'),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _PayTile extends StatelessWidget {
  final String label;
  final String logo;
  final bool selected;
  final VoidCallback onTap;

  const _PayTile({
    required this.label,
    required this.logo,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? AppColors.greenLight : cs.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                selected ? AppColors.green : cs.outline.withValues(alpha: 0.5),
            width: selected ? 1.5 : 0.5,
          ),
        ),
        child: Row(
          children: [
            Text(logo, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: cs.onSurface,
                ),
              ),
            ),
            if (selected)
              const Icon(
                Icons.check_circle_rounded,
                color: AppColors.green,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.green),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: cs.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.greenLight,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.green, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

String _formatDuration(int minutes) {
  final h = minutes ~/ 60;
  final m = minutes % 60;
  return m == 0 ? '${h}h' : '${h}h${m.toString().padLeft(2, '0')}';
}

class _VehiclePhotosCarousel extends ConsumerWidget {
  final String userId;
  final String vehicleId;

  const _VehiclePhotosCarousel({
    required this.userId,
    required this.vehicleId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehiclesAsync = ref.watch(vehiclesProvider(userId));

    return vehiclesAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (vehicles) {
        final vehicle = vehicles.where((v) => v.id == vehicleId).firstOrNull;
        if (vehicle == null || vehicle.photos.isEmpty) {
          return const SizedBox.shrink();
        }

        return Padding(
          padding: const EdgeInsets.only(top: 12),
          child: SizedBox(
            height: 160,
            child: PageView.builder(
              itemCount: vehicle.photos.length,
              itemBuilder: (context, i) {
                final photo = vehicle.photos[i];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          '${ApiEndpoints.gatewayUrl}${photo.photoUrl}',
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.broken_image_rounded, size: 32),
                          ),
                        ),
                      ),
                      if (vehicle.photos.length > 1)
                        Positioned(
                          bottom: 6,
                          right: 6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${i + 1}/${vehicle.photos.length}',
                              style: const TextStyle(color: Colors.white, fontSize: 11),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
