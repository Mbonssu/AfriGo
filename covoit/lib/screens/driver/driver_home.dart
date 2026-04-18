import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app_theme.dart';
import '../../data/models/app_trip.dart';
import '../../data/providers/journey_providers.dart';
import '../../data/providers/user_providers.dart';
import '../notifications_screen.dart';
import '../profile_screen.dart';
import 'driver_passengers_screen.dart';
import 'driver_stats_screen.dart';
import 'driver_trips_screen.dart';
import 'post_trip_screen.dart';
import 'subscription_screen.dart';
import 'vehicles_screen.dart';

class DriverHome extends ConsumerStatefulWidget {
  const DriverHome({super.key});

  @override
  ConsumerState<DriverHome> createState() => _DriverHomeState();
}

class _DriverHomeState extends ConsumerState<DriverHome> {
  int _idx = 0;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.invalidate(currentUserIdProvider));
  }

  @override
  Widget build(BuildContext context) {
    final userIdAsync = ref.watch(currentUserIdProvider);
    final userId = userIdAsync.valueOrNull ?? '';
    final driverAsync = userId.isNotEmpty
        ? ref.watch(driverProfileProvider(userId))
        : null;
    final isPrime = driverAsync?.valueOrNull?.isPrime ?? false;

    final cs = Theme.of(context).colorScheme;
    final accentColor = isPrime ? AppColors.prime : AppColors.green;

    final screens = <Widget>[
      _DriverHomeTab(onNavigate: (i) => setState(() => _idx = i)),
      PostTripScreen(onPublished: () => setState(() => _idx = 2)),
      const DriverTripsScreen(),
      const DriverStatsScreen(),
      const NotificationsScreen(),
      const ProfileScreen(isPassenger: false),
    ];

    final navItems = <BottomNavigationBarItem>[
      const BottomNavigationBarItem(
          icon: Icon(Icons.home_rounded), label: 'Accueil'),
      const BottomNavigationBarItem(
          icon: Icon(Icons.add_circle_rounded), label: 'Publier'),
      const BottomNavigationBarItem(
          icon: Icon(Icons.card_travel_rounded), label: 'Voyages'),
      const BottomNavigationBarItem(
          icon: Icon(Icons.bar_chart_rounded), label: 'Stats'),
      const BottomNavigationBarItem(
          icon: Icon(Icons.notifications_rounded), label: 'Notifs'),
      const BottomNavigationBarItem(
          icon: Icon(Icons.person_rounded), label: 'Profil'),
    ];

    return Scaffold(
      body: IndexedStack(index: _idx, children: screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
              top: BorderSide(
                  color: cs.outline.withValues(alpha: 0.3), width: 0.5)),
          color: isPrime ? const Color(0xFFFFF9F0) : null,
        ),
        child: BottomNavigationBar(
          currentIndex: _idx,
          onTap: (i) => setState(() => _idx = i),
          selectedItemColor: accentColor,
          unselectedItemColor: AppColors.gray400,
          items: navItems,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB ACCUEIL — données dynamiques du conducteur
// ─────────────────────────────────────────────────────────────────────────────

class _DriverHomeTab extends ConsumerWidget {
  final ValueChanged<int> onNavigate;
  const _DriverHomeTab({required this.onNavigate});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userIdAsync = ref.watch(currentUserIdProvider);

    return userIdAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (_, __) => const Scaffold(
          body: Center(child: Text('Impossible de charger le profil'))),
      data: (userId) {
        if (userId == null || userId.isEmpty) {
          return const Scaffold(
              body: Center(child: Text('Utilisateur non connecté')));
        }
        return _DriverHomeTabBody(userId: userId, onNavigate: onNavigate);
      },
    );
  }
}

class _DriverHomeTabBody extends ConsumerWidget {
  final String userId;
  final ValueChanged<int> onNavigate;
  const _DriverHomeTabBody({required this.userId, required this.onNavigate});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final profileAsync = ref.watch(userProfileProvider(userId));
    final tripsAsync = ref.watch(driverTripsByIdProvider(userId));

    final profile = profileAsync.valueOrNull;
    final driverAsync = ref.watch(driverProfileProvider(userId));
    final driverProfile = driverAsync.valueOrNull;
    final fullName = profile?.fullName ?? 'Chauffeur';
    final firstName = profile?.firstName ?? 'Chauffeur';
    final rating = driverProfile?.rating ?? (profile?.rating ?? 0);
    final totalReviews = driverProfile?.ratingCount ?? (profile?.totalReviews ?? 0);
    final isPrime = driverProfile?.isPrime ?? false;

    final allTrips = tripsAsync.valueOrNull ?? [];
    final upcomingTrips =
        allTrips.where((t) => t.status == 'active').toList();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 170,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isPrime
                        ? [const Color(0xFFBA7517), AppColors.prime]
                        : [AppColors.green, AppColors.greenDark],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Bonjour, $firstName 👋',
                                      style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 13)),
                                  Text(fullName,
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 20,
                                          fontWeight: FontWeight.w700)),
                                ],
                              ),
                            ),
                            if (isPrime)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                      color:
                                          Colors.white.withValues(alpha: 0.38),
                                      width: 1),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.workspace_premium_rounded,
                                        size: 14, color: Colors.white),
                                    SizedBox(width: 5),
                                    Text('PRIME',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w800,
                                            fontSize: 12)),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _StatPill(
                                label: rating > 0
                                    ? '${rating.toStringAsFixed(1)} ⭐'
                                    : 'Nouveau',
                                subtle: true),
                            const SizedBox(width: 8),
                            _StatPill(
                                label: '${allTrips.length} trajets',
                                subtle: true),
                            const SizedBox(width: 8),
                            _StatPill(
                                label: '$totalReviews avis', subtle: true),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            title: Text(isPrime ? '237COVOIT PRIME' : '237COVOIT',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 18)),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isPrime)
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const SubscriptionScreen()),
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFBA7517), AppColors.prime],
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.workspace_premium_rounded,
                                color: Colors.white, size: 28),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Devenez Prime',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 15)),
                                  Text(
                                      'Visibilité max · Forum exclusif · +revenus',
                                      style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 12)),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 7),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text('S\'abonner',
                                  style: TextStyle(
                                      color: AppColors.primeDark,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12)),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFBA7517), AppColors.prime],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.prime.withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.workspace_premium_rounded,
                              color: Colors.white, size: 28),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Chauffeur Prime ✨',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 15)),
                                Text(
                                    'Priorité dans les résultats · Badge vérifié',
                                    style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12)),
                              ],
                            ),
                          ),
                          Icon(Icons.verified_rounded,
                              color: Colors.white, size: 22),
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),

                  // Actions rapides
                  Row(
                    children: [
                      Expanded(
                        child: _QuickAction(
                          icon: Icons.add_road_rounded,
                          label: 'Nouveau trajet',
                          color: isPrime ? AppColors.prime : AppColors.green,
                          onTap: () => onNavigate(1),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _QuickAction(
                          icon: Icons.directions_car_rounded,
                          label: 'Mes véhicules',
                          color: isPrime ? AppColors.primeDark : AppColors.greenDark,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const VehiclesScreen()),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _QuickAction(
                          icon: Icons.bar_chart_rounded,
                          label: 'Mes stats',
                          color: isPrime ? AppColors.primeDark : AppColors.prime,
                          onTap: () => onNavigate(3),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),
                  Text('Prochains départs',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: cs.onSurface)),
                  const SizedBox(height: 12),

                  if (tripsAsync.isLoading)
                    const Center(
                        child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(),
                    ))
                  else if (tripsAsync.hasError)
                    Center(
                      child: Column(
                        children: [
                          const Icon(Icons.error_outline_rounded,
                              size: 40, color: AppColors.coral),
                          const SizedBox(height: 8),
                          const Text('Erreur de chargement'),
                          const SizedBox(height: 8),
                          OutlinedButton(
                            onPressed: () => ref.invalidate(
                                driverTripsByIdProvider(userId)),
                            child: const Text('Réessayer'),
                          ),
                        ],
                      ),
                    )
                  else if (upcomingTrips.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            const Icon(Icons.directions_car_rounded,
                                size: 48, color: AppColors.gray100),
                            const SizedBox(height: 12),
                            Text('Aucun trajet à venir',
                                style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: cs.onSurfaceVariant)),
                            const SizedBox(height: 4),
                            Text('Publiez un trajet pour commencer !',
                                style: TextStyle(
                                    fontSize: 13,
                                    color: cs.onSurfaceVariant)),
                          ],
                        ),
                      ),
                    )
                  else
                    ...upcomingTrips.take(3).map((trip) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _DriverTripCard(trip: trip),
                        )),

                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Widgets utilitaires
// ─────────────────────────────────────────────────────────────────────────────

class _StatPill extends StatelessWidget {
  final String label;
  final bool subtle;

  const _StatPill({required this.label, this.subtle = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: subtle ? 0.15 : 0.25),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: const TextStyle(
              color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: cs.outline.withValues(alpha: 0.5), width: 0.5),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(label,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface)),
            ),
          ],
        ),
      ),
    );
  }
}

class _DriverTripCard extends StatelessWidget {
  final AppTrip trip;

  const _DriverTripCard({required this.trip});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isPrime = trip.driver.isPrime;
    final accent = isPrime ? AppColors.prime : AppColors.green;
    final bookedSeats = trip.bookedSeats;
    final pct = trip.totalSeats > 0 ? bookedSeats / trip.totalSeats : 0.0;
    final earnings = trip.pricePerSeat * bookedSeats;
    final dateStr =
        DateFormat('dd MMM', 'fr_FR').format(trip.departureTime);
    final timeStr = DateFormat('HH:mm').format(trip.departureTime);

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
      child: Column(
        children: [
          if (isPrime)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 4),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFBA7517), AppColors.prime],
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.workspace_premium_rounded,
                      size: 12, color: Colors.white),
                  SizedBox(width: 4),
                  Text('TRAJET PRIME',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 10,
                          letterSpacing: 1)),
                ],
              ),
            ),
          Padding(
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
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Icon(Icons.arrow_forward_rounded,
                          size: 16, color: accent),
                    ),
                    Text(trip.to,
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: cs.onSurface)),
                    const Spacer(),
                    Text('$earnings FCFA',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: accent)),
                  ],
                ),
                const SizedBox(height: 6),
                Text('$dateStr · $timeStr',
                    style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text('$bookedSeats/${trip.totalSeats} passagers',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: cs.onSurface)),
                    const Spacer(),
                    Text('${(pct * 100).toInt()}%',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: accent)),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: pct,
                    backgroundColor: AppColors.gray100,
                    valueColor: AlwaysStoppedAnimation(accent),
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DriverPassengersScreen(
                              tripId: trip.id,
                              from: trip.from,
                              to: trip.to,
                              date: dateStr,
                              time: timeStr,
                            ),
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          foregroundColor: accent,
                          side: BorderSide(color: accent.withValues(alpha: 0.5)),
                          textStyle: const TextStyle(fontSize: 12),
                        ),
                        child: const Text('Voir passagers'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const PostTripScreen()),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          foregroundColor: AppColors.coral,
                          side: BorderSide(
                              color: AppColors.coral.withValues(alpha: 0.5)),
                          textStyle: const TextStyle(fontSize: 12),
                        ),
                        child: const Text('Modifier'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
