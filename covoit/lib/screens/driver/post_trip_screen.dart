import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app_theme.dart';
import '../../core/network/api_client_provider.dart';
import '../../data/models/app_vehicle.dart';
import '../../data/providers/journey_providers.dart';
import '../../data/providers/vehicle_providers.dart';
import '../../features/trip/models/waypoint.dart';
import '../../features/trip/widgets/waypoint_manager.dart';
import 'vehicles_screen.dart';

class PostTripScreen extends ConsumerStatefulWidget {
  final VoidCallback? onPublished;

  const PostTripScreen({super.key, this.onPublished});

  @override
  ConsumerState<PostTripScreen> createState() => _PostTripScreenState();
}

class _PostTripScreenState extends ConsumerState<PostTripScreen> {
  final _fromCtrl = TextEditingController();
  final _toCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  AppVehicle? _selectedVehicle;
  int _seats = 3;
  bool _acOk = true;
  bool _smokingOk = false;
  bool _musicOk = true;
  bool _bagsOk = true;
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 2));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 8, minute: 0);
  bool _isPublishing = false;
  List<Waypoint> _waypoints = [];

  @override
  void dispose() {
    _fromCtrl.dispose();
    _toCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  Future<void> _publishTrip() async {
    final from = _fromCtrl.text.trim();
    final to = _toCtrl.text.trim();
    final price = int.tryParse(_priceCtrl.text.trim()) ?? 0;

    if (from.isEmpty || to.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Veuillez renseigner les villes de départ et d\'arrivée.'),
            backgroundColor: AppColors.coral,
          ),
        );
        return;
    }
    if (from.toLowerCase() == to.toLowerCase()) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('La ville de départ et d\'arrivée doivent être différentes.'),
            backgroundColor: AppColors.coral,
          ),
        );
        return;
    }
    if (price < 500 || price > 50000) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Le prix doit être entre 500 et 50 000 FCFA.'),
            backgroundColor: AppColors.coral,
          ),
        );
        return;
    }
    
    // Validation de la date/heure combinée
    final departureDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );
    
    // Vérifier que le départ est au moins 30 minutes dans le futur
    final minimumDeparture = DateTime.now().add(const Duration(minutes: 30));
    if (departureDateTime.isBefore(minimumDeparture)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Le départ doit être prévu au moins 30 minutes à l\'avance.'),
            backgroundColor: AppColors.coral,
          ),
        );
        return;
    }
    
    // Vérifier que le départ n'est pas trop loin dans le futur (90 jours max)
    final maximumDeparture = DateTime.now().add(const Duration(days: 90));
    if (departureDateTime.isAfter(maximumDeparture)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Le départ ne peut pas être prévu à plus de 90 jours.'),
            backgroundColor: AppColors.coral,
          ),
        );
        return;
    }

    if (_selectedVehicle == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner un véhicule.'),
          backgroundColor: AppColors.coral,
        ),
      );
      return;
    }

    setState(() => _isPublishing = true);

    try {
      final storage = ref.read(tokenStorageProvider);
      final userId = await storage.getUserId() ?? '';
      final repository = ref.read(journeyRepositoryProvider);

      final departureTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      final comfortOptions = <String>[
        if (_acOk) 'climatisation',
        if (_musicOk) 'musique',
        if (_smokingOk) 'fumeurs',
        if (_bagsOk) 'bagages',
      ];

      // Convertir les waypoints en format API
      final waypointsData = _waypoints.map((wp) => {
        'city_name': wp.cityName,
        'order_index': wp.orderIndex,
        'estimated_time': wp.estimatedTime.toIso8601String(),
      }).toList();

      await repository.createTrip(
        driverId: userId,
        departureCity: from,
        arrivalCity: to,
        departureTime: departureTime,
        totalSeats: _seats,
        pricePerSeat: price.toDouble(),
        vehicleModel: _selectedVehicle!.displayName,
        vehiclePlate: _selectedVehicle!.plate,
        vehicleId: _selectedVehicle!.id,
        comfortOptions: comfortOptions,
        waypoints: waypointsData,
      );

      // Invalider tous les providers de trajets pour rafraîchir partout
      ref.invalidate(driverTripsProvider);
      ref.invalidate(driverTripsByIdProvider(userId));
      ref.invalidate(allActiveTripsProvider);
      ref.invalidate(popularRoutesProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Trajet publié avec succès !'),
            backgroundColor: AppColors.green,
          ),
        );
        // Reset le formulaire
        _fromCtrl.clear();
        _toCtrl.clear();
        _priceCtrl.clear();
        setState(() {
          _selectedVehicle = null;
          _seats = 3;
          _acOk = true;
          _smokingOk = false;
          _musicOk = true;
          _bagsOk = true;
          _selectedDate = DateTime.now().add(const Duration(days: 2));
          _selectedTime = const TimeOfDay(hour: 8, minute: 0);
        });
        // Naviguer vers l'onglet Voyages
        widget.onPublished?.call();
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
      if (mounted) setState(() => _isPublishing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Publier un trajet')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Route
            const _SectionTitle('Itinéraire'),
            const SizedBox(height: 10),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    _RouteField(
                      controller: _fromCtrl,
                      hint: 'Ville de départ',
                      icon: Icons.radio_button_checked_rounded,
                      iconColor: AppColors.green,
                    ),
                    const SizedBox(height: 12),
                    _RouteField(
                      controller: _toCtrl,
                      hint: 'Ville d\'arrivée',
                      icon: Icons.location_on_rounded,
                      iconColor: AppColors.coral,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Date & time
            const _SectionTitle('Date & heure de départ'),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _PickerTile(
                    icon: Icons.calendar_today_rounded,
                    label: '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                    onTap: () async {
                      final d = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 90)),
                      );
                      if (d != null && mounted) {
                        setState(() => _selectedDate = d);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _PickerTile(
                    icon: Icons.access_time_rounded,
                    label: _selectedTime.format(context),
                    onTap: () async {
                      final t = await showTimePicker(
                        context: context,
                        initialTime: _selectedTime,
                      );
                      if (t != null && mounted) {
                        setState(() => _selectedTime = t);
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Points de ramassage (Waypoints)
            const _SectionTitle('Points de ramassage'),
            const SizedBox(height: 10),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: WaypointManager(
                  initialWaypoints: _waypoints,
                  onWaypointsChanged: (waypoints) {
                    setState(() => _waypoints = waypoints);
                  },
                  departureTime: DateTime(
                    _selectedDate.year,
                    _selectedDate.month,
                    _selectedDate.day,
                    _selectedTime.hour,
                    _selectedTime.minute,
                  ),
                  departureCity: _fromCtrl.text.trim(),
                  arrivalCity: _toCtrl.text.trim(),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Véhicule
            const _SectionTitle('Véhicule'),
            const SizedBox(height: 10),
            _VehicleSelector(
              selectedVehicle: _selectedVehicle,
              onSelected: (v) => setState(() {
                _selectedVehicle = v;
                _seats = v.seats;
              }),
            ),

            const SizedBox(height: 16),

            // Seats & price
            const _SectionTitle('Places & tarif'),
            const SizedBox(height: 10),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.airline_seat_recline_normal_rounded,
                            size: 20, color: cs.onSurfaceVariant),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text('Nombre de places',
                              style: TextStyle(
                                  fontSize: 14, color: cs.onSurface)),
                        ),
                        _Counter(
                          value: _seats,
                          onDecrement: _seats > 1
                              ? () => setState(() => _seats--)
                              : null,
                          onIncrement: _seats < 7
                              ? () => setState(() => _seats++)
                              : null,
                        ),
                      ],
                    ),
                    const Divider(height: 20),
                    Row(
                      children: [
                        Icon(Icons.attach_money_rounded,
                            size: 20, color: cs.onSurfaceVariant),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _priceCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              hintText: 'Prix par personne (FCFA)',
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              fillColor: Colors.transparent,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                        Text('FCFA',
                            style: TextStyle(
                                fontSize: 13, color: cs.onSurfaceVariant)),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Caution notice
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.coralLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_rounded,
                      color: AppColors.coral, size: 16),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'En tant que chauffeur simple, une caution de 500 FCFA × $_seats = ${500 * _seats} FCFA sera requise. Elle est remboursée si vous honorez le trajet.',
                      style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.coral,
                          height: 1.5),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),
            const _SectionTitle('Préférences à bord'),
            const SizedBox(height: 10),
            Card(
              child: Column(
                children: [
                  _PreferenceTile(
                    icon: Icons.ac_unit_rounded,
                    label: 'Climatisation',
                    value: _acOk,
                    onChanged: (v) => setState(() => _acOk = v),
                  ),
                  const Divider(height: 0),
                  _PreferenceTile(
                    icon: Icons.music_note_rounded,
                    label: 'Musique acceptée',
                    value: _musicOk,
                    onChanged: (v) => setState(() => _musicOk = v),
                  ),
                  const Divider(height: 0),
                  _PreferenceTile(
                    icon: Icons.smoke_free_rounded,
                    label: 'Fumeurs acceptés',
                    value: _smokingOk,
                    onChanged: (v) => setState(() => _smokingOk = v),
                  ),
                  const Divider(height: 0),
                  _PreferenceTile(
                    icon: Icons.luggage_rounded,
                    label: 'Bagages acceptés',
                    value: _bagsOk,
                    onChanged: (v) => setState(() => _bagsOk = v),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isPublishing ? null : _publishTrip,
                icon: _isPublishing
                    ? const SizedBox(
                        width: 16, height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.publish_rounded),
                label: Text(_isPublishing ? 'Publication...' : 'Publier le trajet'),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.onSurfaceVariant));
  }
}

class _RouteField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final Color iconColor;

  const _RouteField({
    required this.controller,
    required this.hint,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: hint,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              fillColor: Colors.transparent,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ),
      ],
    );
  }
}

class _PickerTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _PickerTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: cs.outline.withOpacity(0.5), width: 0.5),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.green),
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

class _Counter extends StatelessWidget {
  final int value;
  final VoidCallback? onDecrement;
  final VoidCallback? onIncrement;

  const _Counter({
    required this.value,
    required this.onDecrement,
    required this.onIncrement,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Row(
      children: [
        IconButton(
          onPressed: onDecrement,
          icon: Icon(Icons.remove_circle_outline_rounded,
              color: onDecrement != null ? AppColors.green : cs.outline),
          iconSize: 22,
          visualDensity: VisualDensity.compact,
        ),
        Text('$value',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: cs.onSurface)),
        IconButton(
          onPressed: onIncrement,
          icon: Icon(Icons.add_circle_outline_rounded,
              color: onIncrement != null ? AppColors.green : cs.outline),
          iconSize: 22,
          visualDensity: VisualDensity.compact,
        ),
      ],
    );
  }
}

class _PreferenceTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _PreferenceTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return ListTile(
      leading: Icon(icon,
          size: 20,
          color: value ? AppColors.green : cs.onSurfaceVariant),
      title: Text(label,
          style: TextStyle(fontSize: 14, color: cs.onSurface)),
      trailing: Switch.adaptive(
        value: value,
        onChanged: onChanged,
        activeColor: AppColors.green,
      ),
      dense: true,
    );
  }
}

class _VehicleSelector extends ConsumerWidget {
  final AppVehicle? selectedVehicle;
  final ValueChanged<AppVehicle> onSelected;

  const _VehicleSelector({
    required this.selectedVehicle,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;

    if (selectedVehicle != null) {
      final v = selectedVehicle!;
      return Card(
        child: ListTile(
          leading: Icon(Icons.directions_car_rounded, color: AppColors.green),
          title: Text(v.displayName, style: TextStyle(fontWeight: FontWeight.w600, color: cs.onSurface)),
          subtitle: Text(v.plate, style: TextStyle(color: cs.onSurfaceVariant)),
          trailing: TextButton(
            onPressed: () => _pickVehicle(context, ref),
            child: const Text('Changer'),
          ),
        ),
      );
    }

    return Card(
      child: InkWell(
        onTap: () => _pickVehicle(context, ref),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Icon(Icons.directions_car_rounded, color: cs.outline, size: 28),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Sélectionner un véhicule',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: cs.onSurface)),
                    const SizedBox(height: 2),
                    Text('Choisissez parmi vos véhicules enregistrés',
                        style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: cs.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickVehicle(BuildContext context, WidgetRef ref) async {
    final storage = ref.read(tokenStorageProvider);
    final userId = await storage.getUserId() ?? '';
    if (userId.isEmpty) return;

    // Forcer le chargement et attendre le résultat
    ref.invalidate(vehiclesProvider(userId));
    List<AppVehicle> vehicles = [];
    try {
      vehicles = await ref.read(vehiclesProvider(userId).future);
    } catch (_) {
      vehicles = [];
    }

    if (!context.mounted) return;

    if (vehicles.isEmpty) {
      final goToAdd = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Aucun véhicule'),
          content: const Text('Vous n\'avez pas encore enregistré de véhicule. Voulez-vous en ajouter un ?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
            TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Ajouter')),
          ],
        ),
      );
      if (goToAdd == true && context.mounted) {
        await Navigator.push(context, MaterialPageRoute(builder: (_) => const VehiclesScreen()));
        ref.invalidate(vehiclesProvider(userId));
      }
      return;
    }

    final picked = await showModalBottomSheet<AppVehicle>(
      context: context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text('Choisir un véhicule',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Theme.of(ctx).colorScheme.onSurface)),
                const Spacer(),
                TextButton.icon(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    await Navigator.push(context, MaterialPageRoute(builder: (_) => const VehiclesScreen()));
                    ref.invalidate(vehiclesProvider(userId));
                  },
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Gérer'),
                ),
              ],
            ),
          ),
          const Divider(height: 0),
          ...vehicles.map((v) => ListTile(
                leading: const Icon(Icons.directions_car_rounded, color: AppColors.green),
                title: Text(v.displayName),
                subtitle: Text('${v.plate} • ${v.seats} places'),
                trailing: selectedVehicle?.id == v.id
                    ? const Icon(Icons.check_circle_rounded, color: AppColors.green)
                    : null,
                onTap: () => Navigator.pop(ctx, v),
              )),
          const SizedBox(height: 16),
        ],
      ),
    );

    if (picked != null) onSelected(picked);
  }
}
