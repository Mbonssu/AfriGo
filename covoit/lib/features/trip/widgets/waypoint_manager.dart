import 'package:flutter/material.dart';
import '../../../app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../models/waypoint.dart';

/// Widget pour gérer les points de ramassage (waypoints) lors de la création d'un trajet.
/// 
/// Permet au chauffeur d'ajouter, modifier et supprimer des étapes intermédiaires
/// entre la ville de départ et la ville d'arrivée.
class WaypointManager extends StatefulWidget {
  /// Liste initiale des waypoints
  final List<Waypoint> initialWaypoints;
  
  /// Callback appelé quand la liste des waypoints change
  final ValueChanged<List<Waypoint>> onWaypointsChanged;
  
  /// Heure de départ du trajet (pour calculer les heures estimées)
  final DateTime departureTime;
  
  /// Ville de départ (pour validation)
  final String? departureCity;
  
  /// Ville d'arrivée (pour validation)
  final String? arrivalCity;

  const WaypointManager({
    super.key,
    required this.initialWaypoints,
    required this.onWaypointsChanged,
    required this.departureTime,
    this.departureCity,
    this.arrivalCity,
  });

  @override
  State<WaypointManager> createState() => _WaypointManagerState();
}

class _WaypointManagerState extends State<WaypointManager> {
  late List<Waypoint> _waypoints;

  @override
  void initState() {
    super.initState();
    _waypoints = List.from(widget.initialWaypoints);
  }

  @override
  void didUpdateWidget(WaypointManager oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.departureTime != widget.departureTime) {
      // Recalculer les heures si l'heure de départ change
      setState(() {
        _waypoints = _waypoints.map((wp) {
          final minutesAfterDeparture = wp.estimatedTime.difference(oldWidget.departureTime).inMinutes;
          return wp.copyWith(
            estimatedTime: widget.departureTime.add(Duration(minutes: minutesAfterDeparture)),
          );
        }).toList();
      });
      widget.onWaypointsChanged(_waypoints);
    }
  }

  void _addWaypoint() {
    showDialog(
      context: context,
      builder: (context) => _WaypointDialog(
        departureTime: widget.departureTime,
        existingWaypoints: _waypoints,
        departureCity: widget.departureCity,
        arrivalCity: widget.arrivalCity,
        onSave: (waypoint) {
          setState(() {
            _waypoints.add(waypoint);
            // Réorganiser par ordre d'index
            _waypoints.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
          });
          widget.onWaypointsChanged(_waypoints);
        },
      ),
    );
  }

  void _editWaypoint(int index) {
    showDialog(
      context: context,
      builder: (context) => _WaypointDialog(
        departureTime: widget.departureTime,
        existingWaypoints: _waypoints,
        departureCity: widget.departureCity,
        arrivalCity: widget.arrivalCity,
        initialWaypoint: _waypoints[index],
        onSave: (waypoint) {
          setState(() {
            _waypoints[index] = waypoint;
            _waypoints.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
          });
          widget.onWaypointsChanged(_waypoints);
        },
      ),
    );
  }

  void _removeWaypoint(int index) {
    setState(() {
      _waypoints.removeAt(index);
      // Réorganiser les indices
      for (int i = 0; i < _waypoints.length; i++) {
        _waypoints[i] = _waypoints[i].copyWith(orderIndex: i + 1);
      }
    });
    widget.onWaypointsChanged(_waypoints);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Points de ramassage',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.gray900,
              ),
            ),
            TextButton.icon(
              onPressed: _addWaypoint,
              icon: const Icon(Icons.add_location_alt, size: 18),
              label: const Text('Ajouter'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_waypoints.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.gray100.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.gray100),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: AppColors.gray900.withOpacity(0.6), size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Ajoutez des points de ramassage pour indiquer où vous prendrez les passagers',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.gray900.withOpacity(0.7),
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _waypoints.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final waypoint = _waypoints[index];
              return _WaypointCard(
                waypoint: waypoint,
                onEdit: () => _editWaypoint(index),
                onDelete: () => _removeWaypoint(index),
              );
            },
          ),
      ],
    );
  }
}

/// Card affichant un waypoint
class _WaypointCard extends StatelessWidget {
  final Waypoint waypoint;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _WaypointCard({
    required this.waypoint,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final timeStr = '${waypoint.estimatedTime.hour.toString().padLeft(2, '0')}:${waypoint.estimatedTime.minute.toString().padLeft(2, '0')}';
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.gray100),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.green.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '${waypoint.orderIndex}',
                style: const TextStyle(
                  color: AppColors.green,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  waypoint.cityName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.gray900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Arrivée estimée : $timeStr',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.gray900.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined, size: 20),
            color: AppColors.green,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline, size: 20),
            color: AppColors.coral,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}

/// Dialog pour ajouter/modifier un waypoint
class _WaypointDialog extends StatefulWidget {
  final DateTime departureTime;
  final List<Waypoint> existingWaypoints;
  final String? departureCity;
  final String? arrivalCity;
  final Waypoint? initialWaypoint;
  final ValueChanged<Waypoint> onSave;

  const _WaypointDialog({
    required this.departureTime,
    required this.existingWaypoints,
    this.departureCity,
    this.arrivalCity,
    this.initialWaypoint,
    required this.onSave,
  });

  @override
  State<_WaypointDialog> createState() => _WaypointDialogState();
}

class _WaypointDialogState extends State<_WaypointDialog> {
  late TextEditingController _cityController;
  late TimeOfDay _selectedTime;
  late int _orderIndex;

  @override
  void initState() {
    super.initState();
    _cityController = TextEditingController(
      text: widget.initialWaypoint?.cityName ?? '',
    );
    
    final estimatedTime = widget.initialWaypoint?.estimatedTime ?? 
        widget.departureTime.add(const Duration(hours: 1));
    _selectedTime = TimeOfDay.fromDateTime(estimatedTime);
    
    _orderIndex = widget.initialWaypoint?.orderIndex ?? 
        (widget.existingWaypoints.length + 1);
  }

  @override
  void dispose() {
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _selectTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.green,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (time != null) {
      setState(() => _selectedTime = time);
    }
  }

  void _save() {
    final city = _cityController.text.trim();
    
    if (city.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez entrer le nom de la ville'),
          backgroundColor: AppColors.coral,
        ),
      );
      return;
    }

    // Vérifier que ce n'est pas la ville de départ ou d'arrivée
    if (city.toLowerCase() == widget.departureCity?.toLowerCase() ||
        city.toLowerCase() == widget.arrivalCity?.toLowerCase()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Le point de ramassage ne peut pas être la ville de départ ou d\'arrivée'),
          backgroundColor: AppColors.coral,
        ),
      );
      return;
    }

    final estimatedTime = DateTime(
      widget.departureTime.year,
      widget.departureTime.month,
      widget.departureTime.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    // Vérifier que l'heure est après le départ
    if (estimatedTime.isBefore(widget.departureTime)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('L\'heure d\'arrivée doit être après l\'heure de départ'),
          backgroundColor: AppColors.coral,
        ),
      );
      return;
    }

    final waypoint = Waypoint(
      id: widget.initialWaypoint?.id,
      tripId: widget.initialWaypoint?.tripId,
      cityName: city,
      orderIndex: _orderIndex,
      estimatedTime: estimatedTime,
      createdAt: widget.initialWaypoint?.createdAt,
    );

    widget.onSave(waypoint);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.initialWaypoint == null ? 'Ajouter un point' : 'Modifier le point',
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ville',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.gray900,
              ),
            ),
            const SizedBox(height: 8),
            Autocomplete<String>(
              optionsBuilder: (textEditingValue) {
                if (textEditingValue.text.isEmpty) {
                  return const Iterable<String>.empty();
                }
                return AppConstants.cameroonCities.where((city) {
                  return city.toLowerCase().contains(
                    textEditingValue.text.toLowerCase(),
                  );
                });
              },
              onSelected: (city) {
                _cityController.text = city;
              },
              fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                _cityController = controller;
                return TextField(
                  controller: controller,
                  focusNode: focusNode,
                  decoration: InputDecoration(
                    hintText: 'Ex: Edéa, Mbalmayo...',
                    prefixIcon: const Icon(Icons.location_city, size: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            Text(
              'Heure d\'arrivée estimée',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.gray900,
              ),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: _selectTime,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.gray100),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.access_time, size: 20, color: AppColors.green),
                    const SizedBox(width: 12),
                    Text(
                      '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Position dans le trajet',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.gray900,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<int>(
              value: _orderIndex,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              items: List.generate(
                widget.existingWaypoints.length + 1,
                (index) => DropdownMenuItem(
                  value: index + 1,
                  child: Text('Étape ${index + 1}'),
                ),
              ),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _orderIndex = value);
                }
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.green,
            foregroundColor: Colors.white,
          ),
          child: const Text('Enregistrer'),
        ),
      ],
    );
  }
}
