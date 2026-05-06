import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../app_theme.dart';
import '../models/waypoint.dart';

/// Widget pour afficher les points de ramassage d'un trajet
class WaypointDisplay extends StatelessWidget {
  final List<Waypoint> waypoints;
  final String departureCity;
  final String arrivalCity;
  final DateTime departureTime;

  const WaypointDisplay({
    super.key,
    required this.waypoints,
    required this.departureCity,
    required this.arrivalCity,
    required this.departureTime,
  });

  @override
  Widget build(BuildContext context) {
    if (waypoints.isEmpty) {
      return const SizedBox.shrink();
    }

    // Trier les waypoints par ordre
    final sortedWaypoints = List<Waypoint>.from(waypoints)
      ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.route,
                  color: AppColors.green,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Points de ramassage',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.gray900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _RouteTimeline(
              departureCity: departureCity,
              arrivalCity: arrivalCity,
              departureTime: departureTime,
              waypoints: sortedWaypoints,
            ),
          ],
        ),
      ),
    );
  }
}

/// Timeline affichant l'itinéraire complet avec les waypoints
class _RouteTimeline extends StatelessWidget {
  final String departureCity;
  final String arrivalCity;
  final DateTime departureTime;
  final List<Waypoint> waypoints;

  const _RouteTimeline({
    required this.departureCity,
    required this.arrivalCity,
    required this.departureTime,
    required this.waypoints,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Point de départ
        _TimelineItem(
          time: DateFormat('HH:mm').format(departureTime),
          city: departureCity,
          isFirst: true,
          isLast: false,
        ),
        
        // Waypoints intermédiaires
        ...waypoints.map((waypoint) => _TimelineItem(
          time: DateFormat('HH:mm').format(waypoint.estimatedTime),
          city: waypoint.cityName,
          isFirst: false,
          isLast: false,
          isWaypoint: true,
        )),
        
        // Point d'arrivée (on estime l'heure si pas de waypoint)
        _TimelineItem(
          time: '~${_estimateArrivalTime()}',
          city: arrivalCity,
          isFirst: false,
          isLast: true,
        ),
      ],
    );
  }

  String _estimateArrivalTime() {
    // Si on a des waypoints, on ajoute 1h après le dernier
    if (waypoints.isNotEmpty) {
      final lastWaypoint = waypoints.last;
      final arrivalTime = lastWaypoint.estimatedTime.add(const Duration(hours: 1));
      return DateFormat('HH:mm').format(arrivalTime);
    }
    // Sinon on estime basé sur le départ
    final arrivalTime = departureTime.add(const Duration(hours: 3));
    return DateFormat('HH:mm').format(arrivalTime);
  }
}

/// Item de la timeline
class _TimelineItem extends StatelessWidget {
  final String time;
  final String city;
  final bool isFirst;
  final bool isLast;
  final bool isWaypoint;

  const _TimelineItem({
    required this.time,
    required this.city,
    required this.isFirst,
    required this.isLast,
    this.isWaypoint = false,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Colonne de temps
          SizedBox(
            width: 50,
            child: Text(
              time,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isWaypoint ? FontWeight.w500 : FontWeight.w600,
                color: isWaypoint 
                    ? AppColors.gray900.withOpacity(0.7)
                    : AppColors.gray900,
              ),
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Timeline visuelle
          Column(
            children: [
              // Ligne du haut
              if (!isFirst)
                Container(
                  width: 2,
                  height: 8,
                  color: isWaypoint 
                      ? AppColors.green.withOpacity(0.3)
                      : AppColors.green,
                ),
              
              // Point/Icône
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: isWaypoint 
                      ? Colors.white
                      : (isFirst ? AppColors.green : AppColors.coral),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isWaypoint 
                        ? AppColors.green
                        : (isFirst ? AppColors.green : AppColors.coral),
                    width: isWaypoint ? 2 : 3,
                  ),
                ),
                child: isWaypoint
                    ? Center(
                        child: Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: AppColors.green,
                            shape: BoxShape.circle,
                          ),
                        ),
                      )
                    : null,
              ),
              
              // Ligne du bas
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: isWaypoint 
                        ? AppColors.green.withOpacity(0.3)
                        : AppColors.green,
                  ),
                ),
            ],
          ),
          
          const SizedBox(width: 12),
          
          // Nom de la ville
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    city,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: isWaypoint ? FontWeight.w500 : FontWeight.w600,
                      color: AppColors.gray900,
                    ),
                  ),
                  if (isWaypoint)
                    Text(
                      'Point de ramassage',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.gray900.withOpacity(0.5),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
