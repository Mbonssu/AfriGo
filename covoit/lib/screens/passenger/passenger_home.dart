import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../app_theme.dart';
import '../../data/providers/journey_providers.dart';
import '../../data/providers/user_providers.dart';
import 'search_screen.dart';
import 'my_trips_screen.dart';
import '../notifications_screen.dart';
import '../profile_screen.dart';
import '../auth/login_screen.dart';
import '../auth/register_screen.dart';
import 'trip_detail_screen.dart';

class PassengerHome extends ConsumerStatefulWidget {
  const PassengerHome({
    super.key,
    this.startAuthenticated = false,
  });

  final bool startAuthenticated;

  @override
  ConsumerState<PassengerHome> createState() => _PassengerHomeState();
}

class _PassengerHomeState extends ConsumerState<PassengerHome> {
  int _idx = 0;
  late bool _isAuthenticated;

  List<Widget> get _screens => [
        _HomeTab(
          isAuthenticated: _isAuthenticated,
          onAuthRequired: _showAuthDialog,
        ),
        const SearchScreen(),
        const MyTripsScreen(),
        const NotificationsScreen(),
        const ProfileScreen(isPassenger: true),
      ];

  @override
  void initState() {
    super.initState();
    _isAuthenticated = widget.startAuthenticated;
    if (_isAuthenticated) {
      // Forcer le rechargement des données utilisateur après le login
      Future.microtask(() {
        ref.invalidate(currentUserIdProvider);
      });
    }
  }

  void _showAuthDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AuthDialogWidget(
        onLogin: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          ).then((authenticated) {
            if (authenticated == true) {
              setState(() => _isAuthenticated = true);
            }
          });
        },
        onRegister: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const RegisterScreen()),
          ).then((authenticated) {
            if (authenticated == true) {
              setState(() => _isAuthenticated = true);
            }
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: IndexedStack(index: _idx, children: _screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
              top: BorderSide(color: cs.outline.withOpacity(0.3), width: 0.5)),
        ),
        child: BottomNavigationBar(
          currentIndex: _idx,
          onTap: (i) => setState(() => _idx = i),
          items: const [
            BottomNavigationBarItem(
                icon: Icon(Icons.home_rounded), label: 'Accueil'),
            BottomNavigationBarItem(
                icon: Icon(Icons.search_rounded), label: 'Recherche'),
            BottomNavigationBarItem(
                icon: Icon(Icons.card_travel_rounded), label: 'Voyages'),
            BottomNavigationBarItem(
                icon: Icon(Icons.notifications_rounded), label: 'Notifs'),
            BottomNavigationBarItem(
                icon: Icon(Icons.person_rounded), label: 'Profil'),
          ],
        ),
      ),
    );
  }
}

class _HomeTab extends ConsumerWidget {
  final bool isAuthenticated;
  final VoidCallback onAuthRequired;

  const _HomeTab({
    required this.isAuthenticated,
    required this.onAuthRequired,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;

    final userIdAsync = ref.watch(currentUserIdProvider);
    final userId = userIdAsync.valueOrNull;
    final profileAsync = userId != null && userId.isNotEmpty
        ? ref.watch(userProfileProvider(userId))
        : null;
    final profile = profileAsync?.valueOrNull;

    final displayName = profile?.fullName ?? 'Voyageur';
    final initials = profile?.initials ?? '?';

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 160,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.green, AppColors.greenDark],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Bonjour 👋',
                                    style: TextStyle(
                                        color: Colors.white70, fontSize: 13)),
                                const SizedBox(height: 2),
                                Text(displayName,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.w700,
                                        )),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            title: const Text('AfriGo'),
            actions: [
              // Avatar fixe à droite
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.white.withValues(alpha: 0.25),
                  child: Text(
                    initials,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (!isAuthenticated)
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.green.withOpacity(0.1),
                      AppColors.prime.withOpacity(0.08),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.green.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.lock_open_rounded,
                          color: AppColors.green,
                          size: 22,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Connecte-toi pour réserver',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Accès complet à tous les trajets',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: onAuthRequired,
                            icon: const Icon(Icons.login_rounded, size: 16),
                            label: const Text('Se connecter'),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppColors.green, width: 1.5),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: onAuthRequired,
                            icon: const Icon(Icons.person_add_rounded, size: 16),
                            label: const Text('S\'inscrire'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.green,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Quick search card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Où allez-vous ?',
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: cs.onSurface)),
                          const SizedBox(height: 14),
                          const _SearchRow(
                            icon: Icons.radio_button_checked_rounded,
                            iconColor: AppColors.green,
                            hint: 'Départ — ex: Douala',
                          ),
                          const Divider(height: 16),
                          const _SearchRow(
                            icon: Icons.location_on_rounded,
                            iconColor: AppColors.coral,
                            hint: 'Destination — ex: Yaoundé',
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: _DateChip(
                                  icon: Icons.calendar_today_rounded,
                                  label: 'Auj. ${DateFormat('d MMM', 'fr_FR').format(DateTime.now())}',
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: _DateChip(
                                  icon: Icons.people_rounded,
                                  label: '1 passager',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const SearchScreen()),
                              ),
                              icon: const Icon(Icons.search_rounded, size: 18),
                              label: const Text('Rechercher un trajet'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                  Text('Trajets populaires',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: cs.onSurface)),
                  const SizedBox(height: 12),

                  // Popular routes (dynamiques)
                  SizedBox(
                    height: 105,
                    child: _PopularRoutesRow(ref: ref),
                  ),

                  const SizedBox(height: 20),
                  Text('Prochains voyages disponibles',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: cs.onSurface)),
                  const SizedBox(height: 12),

                  // Trajets actifs toutes destinations confondues
                  _UpcomingTripsSection(ref: ref),

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

class _UpcomingTripsSection extends StatelessWidget {
  final WidgetRef ref;
  const _UpcomingTripsSection({required this.ref});

  @override
  Widget build(BuildContext context) {
    final query = const TripSearchQuery(from: '', to: '');
    final tripsAsync = ref.watch(searchTripsProvider(query));

    return tripsAsync.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(color: AppColors.green),
        ),
      ),
      error: (_, __) => const Padding(
        padding: EdgeInsets.all(16),
        child: Text('Impossible de charger les trajets',
            style: TextStyle(color: AppColors.gray400, fontSize: 13)),
      ),
      data: (trips) {
        if (trips.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Aucun trajet disponible',
                style: TextStyle(color: AppColors.gray400, fontSize: 13)),
          );
        }
        final shown = trips.take(5).toList();
        return Column(
          children: shown.map((trip) {
            final dateStr =
                '${trip.departureTime.day}/${trip.departureTime.month}';
            final timeStr =
                '${trip.departureTime.hour.toString().padLeft(2, '0')}:${trip.departureTime.minute.toString().padLeft(2, '0')}';
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _TripCard(
                from: trip.from,
                to: trip.to,
                time: timeStr,
                date: dateStr,
                driverName: trip.driver.fullName,
                isPrime: trip.driver.isPrime,
                price: trip.pricePerSeat.toString(),
                seats: trip.availableSeats,
                rating: trip.driver.rating,
                onBook: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TripDetailScreen(trip: trip),
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _SearchRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String hint;

  const _SearchRow({
    required this.icon,
    required this.iconColor,
    required this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(hint,
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 14)),
        ),
      ],
    );
  }
}

class _DateChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _DateChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cs.outline.withOpacity(0.5), width: 0.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 14, color: AppColors.green),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface)),
        ],
      ),
    );
  }
}

class _PopularRoutesRow extends StatelessWidget {
  final WidgetRef ref;
  const _PopularRoutesRow({required this.ref});

  static const _fallback = [
    {'from': 'Douala', 'to': 'Yaoundé', 'avg_price': 3500, 'trip_count': 0},
    {'from': 'Yaoundé', 'to': 'Bafoussam', 'avg_price': 2500, 'trip_count': 0},
    {'from': 'Douala', 'to': 'Limbé', 'avg_price': 1500, 'trip_count': 0},
    {'from': 'Yaoundé', 'to': 'Bertoua', 'avg_price': 4000, 'trip_count': 0},
  ];

  @override
  Widget build(BuildContext context) {
    final routesAsync = ref.watch(popularRoutesProvider);

    return routesAsync.when(
      loading: () => ListView(
        scrollDirection: Axis.horizontal,
        children: _fallback
            .map((r) => _RouteChip(
                  from: r['from'] as String,
                  to: r['to'] as String,
                  price: '${r['avg_price']}',
                  tripCount: r['trip_count'] as int,
                ))
            .toList(),
      ),
      error: (_, __) => ListView(
        scrollDirection: Axis.horizontal,
        children: _fallback
            .map((r) => _RouteChip(
                  from: r['from'] as String,
                  to: r['to'] as String,
                  price: '${r['avg_price']}',
                  tripCount: r['trip_count'] as int,
                ))
            .toList(),
      ),
      data: (routes) {
        final items = routes.isNotEmpty ? routes : _fallback;
        return ListView(
          scrollDirection: Axis.horizontal,
          children: items
              .map((r) => _RouteChip(
                    from: (r['from'] ?? '') as String,
                    to: (r['to'] ?? '') as String,
                    price: '${r['avg_price'] ?? 0}',
                    tripCount: (r['trip_count'] ?? 0) as int,
                  ))
              .toList(),
        );
      },
    );
  }
}

class _RouteChip extends StatelessWidget {
  final String from;
  final String to;
  final String price;
  final int tripCount;

  const _RouteChip({
    required this.from,
    required this.to,
    required this.price,
    required this.tripCount,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outline.withOpacity(0.5), width: 0.5),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(from,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface)),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 6),
                child: Icon(Icons.arrow_forward_rounded,
                    size: 14, color: AppColors.green),
              ),
              Text(to,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface)),
            ],
          ),
          const SizedBox(height: 4),
          Text('à partir de $price FCFA',
              style: const TextStyle(
                  fontSize: 11, color: AppColors.green, fontWeight: FontWeight.w500)),
          const SizedBox(height: 2),
          Text(
            tripCount > 0 
                ? '$tripCount voyage${tripCount > 1 ? 's' : ''} disponible${tripCount > 1 ? 's' : ''}'
                : 'Aucun voyage',
            style: TextStyle(
              fontSize: 10,
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _TripCard extends StatelessWidget {
  final String from;
  final String to;
  final String time;
  final String date;
  final String driverName;
  final bool isPrime;
  final String price;
  final int seats;
  final double rating;
  final VoidCallback? onBook;

  const _TripCard({
    required this.from,
    required this.to,
    required this.time,
    required this.date,
    required this.driverName,
    required this.isPrime,
    required this.price,
    required this.seats,
    required this.rating,
    this.onBook,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final initials = driverName.split(' ').map((e) => e[0]).take(2).join();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor:
                      isPrime ? AppColors.primeBg : AppColors.greenLight,
                  child: Text(initials,
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color:
                              isPrime ? AppColors.primeDark : AppColors.greenDark)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(driverName,
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: cs.onSurface)),
                          if (isPrime) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primeBg,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.workspace_premium_rounded,
                                      size: 10, color: AppColors.prime),
                                  SizedBox(width: 2),
                                  Text('PRIME',
                                      style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.primeDark)),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                      Row(
                        children: [
                          const Icon(Icons.star_rounded,
                              size: 12, color: AppColors.prime),
                          const SizedBox(width: 2),
                          Text('$rating',
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.gray600,
                                  fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('$price F',
                        style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: AppColors.green)),
                    Text('/personne',
                        style: TextStyle(
                            fontSize: 10, color: cs.onSurfaceVariant)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.location_on_rounded,
                    size: 14, color: AppColors.green),
                const SizedBox(width: 4),
                Text(from,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface)),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(Icons.arrow_forward_rounded,
                      size: 14, color: AppColors.gray400),
                ),
                Text(to,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface)),
                const Spacer(),
                Icon(Icons.access_time_rounded,
                    size: 13, color: cs.onSurfaceVariant),
                const SizedBox(width: 3),
                Text('$time · $date',
                    style: TextStyle(
                        fontSize: 11, color: cs.onSurfaceVariant)),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _Chip(
                    icon: Icons.airline_seat_recline_normal_rounded,
                    label: '$seats place${seats > 1 ? 's' : ''}'),
                const SizedBox(width: 8),
                const _Chip(icon: Icons.phone_android_rounded, label: 'Mobile Money'),
                const Spacer(),
                ElevatedButton(
                  onPressed: onBook,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    minimumSize: Size.zero,
                    textStyle: const TextStyle(fontSize: 12),
                  ),
                  child: const Text('Réserver'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _Chip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outline.withOpacity(0.4), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: cs.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _AuthDialogWidget extends StatelessWidget {
  final VoidCallback onLogin;
  final VoidCallback onRegister;

  const _AuthDialogWidget({
    required this.onLogin,
    required this.onRegister,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final mediaQuery = MediaQuery.of(context);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 24,
            bottom: mediaQuery.viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: cs.outline.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Align(
                alignment: Alignment.center,
                child: Column(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppColors.green.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.lock_open_rounded,
                        color: AppColors.green,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Accès aux réservations',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Crée un compte ou connecte-toi pour réserver tes trajets',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: cs.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Features list
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Column(
                  children: [
                    _FeatureRow(
                      icon: Icons.verified_user_rounded,
                      title: 'Chauffeurs vérifiés',
                      subtitle: '100% contrôlés et notés',
                    ),
                    Divider(height: 16, thickness: 0.5),
                    _FeatureRow(
                      icon: Icons.shield_rounded,
                      title: 'Paiements sécurisés',
                      subtitle: 'Mobile Money & Orange Money',
                    ),
                    Divider(height: 16, thickness: 0.5),
                    _FeatureRow(
                      icon: Icons.star_rounded,
                      title: 'Meilleurs trajets',
                      subtitle: 'Chauffeurs Prime en avant',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Buttons
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onRegister,
                  icon: const Icon(Icons.person_add_rounded, size: 18),
                  label: const Text('Créer un compte'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.green,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onLogin,
                  icon: const Icon(Icons.login_rounded, size: 18),
                  label: const Text('Se connecter'),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.green, width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),

              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Continuer sans se connecter',
                  style: TextStyle(
                    color: cs.onSurfaceVariant,
                    fontSize: 13,
                  ),
                ),
              ),

              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _FeatureRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Row(
      children: [
        Icon(
          icon,
          color: AppColors.green,
          size: 20,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
