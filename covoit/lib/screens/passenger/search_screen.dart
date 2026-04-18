import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/app_trip.dart';
import '../../data/providers/journey_providers.dart';
import 'trip_detail_screen.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _fromCtrl = TextEditingController();
  final _toCtrl = TextEditingController();
  DateTime? _selectedDate;
  int _passengerCount = 1;
  String _selectedSort = 'departure_time';
  String _focusedField = '';
  List<String> _suggestions = [];
  TripSearchQuery? _activeQuery;

  @override
  void dispose() {
    _fromCtrl.dispose();
    _toCtrl.dispose();
    super.dispose();
  }

  void _updateSuggestions(String query, String field) {
    setState(() {
      _focusedField = field;
      _suggestions = query.isEmpty
          ? []
          : AppConstants.cameroonCities
              .where((city) => city.toLowerCase().startsWith(query.toLowerCase()))
              .toList();
    });
  }

  void _selectSuggestion(String city) {
    if (_focusedField == 'from') {
      _fromCtrl.text = city;
    } else {
      _toCtrl.text = city;
    }
    setState(() => _suggestions = []);
  }

  Future<void> _pickDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (pickedDate != null) {
      setState(() => _selectedDate = pickedDate);
      _refreshQueryIfNeeded();
    }
  }

  Future<void> _pickPassengerCount() async {
    final selected = await showModalBottomSheet<int>(
      context: context,
      builder: (context) => SafeArea(
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: 6,
          itemBuilder: (context, index) {
            final count = index + 1;
            return ListTile(
              title: Text('$count passager${count > 1 ? 's' : ''}'),
              trailing: count == _passengerCount ? const Icon(Icons.check_rounded) : null,
              onTap: () => Navigator.pop(context, count),
            );
          },
        ),
      ),
    );

    if (selected != null) {
      setState(() => _passengerCount = selected);
      _refreshQueryIfNeeded();
    }
  }

  void _performSearch() {
    final from = _fromCtrl.text.trim();
    final to = _toCtrl.text.trim();

    if (from.isEmpty || to.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Choisissez la ville de départ et la ville d\'arrivée.'),
        ),
      );
      return;
    }
    if (from.toLowerCase() == to.toLowerCase()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La ville de départ et d\'arrivée doivent être différentes.'),
        ),
      );
      return;
    }

    setState(() {
      _suggestions = [];
      _activeQuery = TripSearchQuery(
        from: from,
        to: to,
        departureDate: _selectedDate,
        passengerCount: _passengerCount,
        sortBy: _selectedSort == 'rating' ? 'departure_time' : _selectedSort,
      );
    });
  }

  void _changeSort(String sort) {
    setState(() => _selectedSort = sort);
    _refreshQueryIfNeeded();
  }

  void _refreshQueryIfNeeded() {
    if (_activeQuery == null) return;
    _activeQuery = TripSearchQuery(
      from: _fromCtrl.text.trim(),
      to: _toCtrl.text.trim(),
      departureDate: _selectedDate,
      passengerCount: _passengerCount,
      sortBy: _selectedSort == 'rating' ? 'departure_time' : _selectedSort,
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final resultsAsync =
        _activeQuery == null ? null : ref.watch(searchTripsProvider(_activeQuery!));

    return Scaffold(
      appBar: AppBar(title: const Text('Rechercher un trajet')),
      body: Column(
        children: [
          Container(
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.dark800
                : AppColors.green,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _AutocompleteField(
                  controller: _fromCtrl,
                  hint: 'Ville de départ',
                  icon: Icons.radio_button_checked_rounded,
                  iconColor: Colors.white,
                  onChanged: (value) => _updateSuggestions(value, 'from'),
                ),
                const SizedBox(height: 8),
                _AutocompleteField(
                  controller: _toCtrl,
                  hint: 'Ville d\'arrivée',
                  icon: Icons.location_on_rounded,
                  iconColor: Colors.white70,
                  onChanged: (value) => _updateSuggestions(value, 'to'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _FilterChip(
                        icon: Icons.calendar_today_rounded,
                        label: _selectedDate == null
                            ? 'Date flexible'
                            : DateFormat('dd/MM/yyyy').format(_selectedDate!),
                        onTap: _pickDate,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _FilterChip(
                        icon: Icons.people_rounded,
                        label: '$_passengerCount passager${_passengerCount > 1 ? 's' : ''}',
                        onTap: _pickPassengerCount,
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _performSearch,
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.search_rounded, color: AppColors.green),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (_suggestions.isNotEmpty)
            Container(
              constraints: const BoxConstraints(maxHeight: 200),
              decoration: BoxDecoration(
                color: cs.surface,
                border: Border(
                  bottom: BorderSide(color: cs.outline.withValues(alpha: 0.3), width: 0.5),
                ),
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _suggestions.length,
                itemBuilder: (context, index) => ListTile(
                  dense: true,
                  leading: const Icon(
                    Icons.location_city_rounded,
                    size: 18,
                    color: AppColors.green,
                  ),
                  title: Text(
                    _suggestions[index],
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: cs.onSurface,
                    ),
                  ),
                  onTap: () => _selectSuggestion(_suggestions[index]),
                ),
              ),
            ),
          Container(
            color: cs.surface,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Text(
                  'Trier par:',
                  style: TextStyle(
                    fontSize: 12,
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 8),
                _SortChip(
                  label: 'Heure',
                  selected: _selectedSort == 'departure_time',
                  onTap: () => _changeSort('departure_time'),
                ),
                const SizedBox(width: 6),
                _SortChip(
                  label: 'Prix',
                  selected: _selectedSort == 'price',
                  onTap: () => _changeSort('price'),
                ),
                const SizedBox(width: 6),
                _SortChip(
                  label: 'Note',
                  selected: _selectedSort == 'rating',
                  onTap: () => _changeSort('rating'),
                ),
              ],
            ),
          ),
          Expanded(
            child: _SearchResultsView(
              query: _activeQuery,
              selectedSort: _selectedSort,
              resultsAsync: resultsAsync,
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchResultsView extends StatelessWidget {
  final TripSearchQuery? query;
  final String selectedSort;
  final AsyncValue<List<AppTrip>>? resultsAsync;

  const _SearchResultsView({
    required this.query,
    required this.selectedSort,
    required this.resultsAsync,
  });

  @override
  Widget build(BuildContext context) {
    if (query == null || resultsAsync == null) {
      return const _EmptyState(
        icon: Icons.travel_explore_rounded,
        title: 'Lancez une recherche',
        subtitle: 'Choisissez un départ, une destination et consultez les trajets disponibles.',
      );
    }

    return resultsAsync!.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _EmptyState(
        icon: Icons.cloud_off_rounded,
        title: 'Impossible de charger les trajets',
        subtitle: error.toString(),
      ),
      data: (trips) {
        final visibleTrips = [...trips];
        if (selectedSort == 'rating') {
          visibleTrips.sort((a, b) => b.driver.rating.compareTo(a.driver.rating));
        }

        if (visibleTrips.isEmpty) {
          return _EmptyState(
            icon: Icons.route_rounded,
            title: 'Aucun trajet trouvé',
            subtitle: 'Aucun trajet ${query!.from} → ${query!.to} ne correspond aux critères actuels.',
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: visibleTrips.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) => _SearchResultCard(trip: visibleTrips[index]),
        );
      },
    );
  }
}

class _AutocompleteField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final Color iconColor;
  final ValueChanged<String> onChanged;

  const _AutocompleteField({
    required this.controller,
    required this.hint,
    required this.icon,
    required this.iconColor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white60, fontSize: 14),
        prefixIcon: Icon(icon, color: iconColor, size: 20),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.15),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.38), width: 1),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _FilterChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withValues(alpha: 0.24), width: 0.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: Colors.white70),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SortChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SortChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? AppColors.greenLight : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? AppColors.green
                : Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
            width: 0.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: selected
                ? AppColors.greenDark
                : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _SearchResultCard extends StatelessWidget {
  final AppTrip trip;

  const _SearchResultCard({required this.trip});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final departureTime = DateFormat('HH:mm').format(trip.departureTime);
    final arrivalTime =
        DateFormat('HH:mm').format(trip.departureTime.add(const Duration(hours: 4)));
    final features =
        trip.comfortOptions.isEmpty ? const ['Trajet standard'] : trip.comfortOptions;
    final initials = trip.driver.fullName
        .split(' ')
        .where((part) => part.isNotEmpty)
        .map((part) => part[0])
        .take(2)
        .join();

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => TripDetailScreen(trip: trip)),
      ),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (trip.driver.isPrime)
                Align(
                  alignment: Alignment.topRight,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primeBg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.workspace_premium_rounded, size: 11, color: AppColors.prime),
                        SizedBox(width: 3),
                        Text(
                          'PRIME',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primeDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        departureTime,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: cs.onSurface,
                        ),
                      ),
                      Text(trip.from, style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                    ],
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Row(
                        children: [
                          Expanded(child: Container(height: 1.5, color: cs.outline.withValues(alpha: 0.3))),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              '${trip.availableSeats} place${trip.availableSeats > 1 ? 's' : ''}',
                              style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant),
                            ),
                          ),
                          Expanded(child: Container(height: 1.5, color: cs.outline.withValues(alpha: 0.3))),
                        ],
                      ),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        arrivalTime,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: cs.onSurface,
                        ),
                      ),
                      Text(trip.to, style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                    ],
                  ),
                ],
              ),
              const Divider(height: 16),
              Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor:
                        trip.driver.isPrime ? AppColors.primeBg : AppColors.greenLight,
                    child: Text(
                      initials.isEmpty ? 'CH' : initials,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: trip.driver.isPrime ? AppColors.primeDark : AppColors.greenDark,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          trip.driver.fullName,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: cs.onSurface,
                          ),
                        ),
                        Row(
                          children: [
                            const Icon(Icons.star_rounded, size: 12, color: AppColors.prime),
                            const SizedBox(width: 2),
                            Text(
                              trip.driver.ratingCount > 0
                                  ? '${trip.driver.rating.toStringAsFixed(1)} (${trip.driver.ratingCount} avis)'
                                  : 'Nouveau chauffeur',
                              style: const TextStyle(fontSize: 11, color: AppColors.gray600),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${trip.pricePerSeat} F',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.green,
                        ),
                      ),
                      Text('/place', style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: features.take(3).map((feature) => _FeatureChip(label: feature)).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  final String label;

  const _FeatureChip({required this.label});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: cs.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 56, color: AppColors.gray100),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: cs.onSurface),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}
