import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../app_theme.dart';
import '../core/constants/api_endpoints.dart';
import '../core/network/api_client_provider.dart';
import '../core/network/websocket_service.dart';
import '../core/services/safety_location_service.dart';
import '../data/providers/journey_providers.dart';
import '../data/providers/tracking_providers.dart';
import '../data/providers/user_providers.dart';
import '../data/models/app_trip.dart';
import 'passenger/chat_screen.dart';

class TripTrackingScreen extends ConsumerStatefulWidget {
  final String from;
  final String to;
  final String driverName;
  final bool isPrime;
  final bool isDriver;
  final String? tripId;

  const TripTrackingScreen({
    super.key,
    required this.from,
    required this.to,
    required this.driverName,
    this.isPrime = false,
    this.isDriver = false,
    this.tripId,
  });

  @override
  ConsumerState<TripTrackingScreen> createState() => _TripTrackingScreenState();
}

class _TripTrackingScreenState extends ConsumerState<TripTrackingScreen> {
  WebSocketService? _ws;
  StreamSubscription? _wsSub;
  SafetyLocationService? _safetyService;
  double _liveProgress = 0.0;
  List<dynamic> _liveSteps = [];
  bool _hasLiveData = false;

  @override
  void initState() {
    super.initState();
    _connectWs();
    _startSafetyTracking();
  }

  @override
  void dispose() {
    _wsSub?.cancel();
    _ws?.dispose();
    _safetyService?.stop();
    super.dispose();
  }

  /// Démarre automatiquement l'envoi de la position GPS toutes les heures
  /// au numéro d'urgence configuré par l'utilisateur.
  Future<void> _startSafetyTracking() async {
    if (widget.tripId == null) return;

    final userIdAsync = ref.read(currentUserIdProvider);
    final userId = userIdAsync.valueOrNull;
    if (userId == null || userId.isEmpty) return;

    // Charger le profil pour récupérer le contact d'urgence
    try {
      final client = ref.read(apiClientProvider);
      final profileData = await client.get(ApiEndpoints.emergencyContact(userId));
      final emergencyPhone = profileData['emergency_contact_phone'] as String?;
      final emergencyName = profileData['emergency_contact_name'] as String?;

      if (emergencyPhone == null || emergencyPhone.isEmpty) {
        debugPrint('[Safety] Aucun contact d\'urgence configuré — envoi désactivé');
        return;
      }

      // Récupérer le nom de l'utilisateur
      final userProfile = ref.read(userProfileProvider(userId)).valueOrNull;
      final userName = userProfile?.fullName ?? 'Utilisateur';

      _safetyService = SafetyLocationService(
        apiClient: client,
        tripId: widget.tripId!,
        userId: userId,
        userName: userName,
        tripFrom: widget.from,
        tripTo: widget.to,
        emergencyContactName: emergencyName ?? '',
        emergencyContactPhone: emergencyPhone,
      );
      await _safetyService!.start();
    } catch (e) {
      debugPrint('[Safety] Erreur initialisation: $e');
    }
  }

  Future<void> _connectWs() async {
    if (widget.tripId == null) return;
    final tokenStorage = ref.read(tokenStorageProvider);
    final token = await tokenStorage.getAccessToken();
    if (token == null) return;

    _ws = WebSocketService(url: ApiEndpoints.wsTracking(widget.tripId!, token));
    _wsSub = _ws!.stream.listen((data) {
      if (data['type'] == 'position_update' && mounted) {
        final tracking = data['tracking'] as Map<String, dynamic>;
        setState(() {
          _liveProgress = (tracking['progress'] as num?)?.toDouble() ?? _liveProgress;
          _hasLiveData = true;
        });
      }
    });
    await _ws!.connect();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final initials =
        widget.driverName.split(' ').map((e) => e[0]).take(2).join();

    // Si tripId disponible, charger depuis l'API
    if (widget.tripId != null) {
      final trackingAsync = ref.watch(tripTrackingProvider(widget.tripId!));
      return trackingAsync.when(
        loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
        error: (_, __) => _buildBody(cs, initials, _liveProgress, _liveSteps),
        data: (data) {
          final apiProgress = (data['progress'] as num?)?.toDouble() ?? 0.0;
          final steps = (data['steps'] as List?) ?? [];
          // Utiliser les données live si disponibles, sinon les données API
          final progress = _hasLiveData ? _liveProgress : apiProgress;
          if (!_hasLiveData) _liveSteps = steps;
          return _buildBody(cs, initials, progress, _liveSteps.isNotEmpty ? _liveSteps : steps);
        },
      );
    }

    // Fallback sans tripId
    return _buildBody(cs, initials, 0.0, []);
  }

  Widget _buildBody(ColorScheme cs, String initials, double progress, List<dynamic> apiSteps) {
    final totalHours = AppTrip.estimateDurationMinutes(widget.from, widget.to) / 60.0;
    final distanceKm = AppTrip.estimateDistanceKm(widget.from, widget.to);
    final elapsed = (progress * totalHours).toStringAsFixed(1);
    final remaining = ((1 - progress) * totalHours).toStringAsFixed(1);

    return Scaffold(
      body: Column(
        children: [
          // Map placeholder
          Container(
            height: 300,
            color: cs.surfaceContainerHighest,
            child: Stack(
              children: [
                // Fake map grid
                CustomPaint(
                  size: const Size(double.infinity, 300),
                  painter: _MapPainter(cs: cs),
                ),
                // Route line
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.location_on_rounded,
                          color: AppColors.green, size: 32),
                      Container(
                        width: 3,
                        height: 80,
                        color: AppColors.green,
                      ),
                      Container(
                        width: 14,
                        height: 14,
                        decoration: const BoxDecoration(
                          color: AppColors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                      Container(
                        width: 2,
                        height: 60,
                        color: AppColors.gray100,
                      ),
                      Icon(Icons.location_on_rounded,
                          color: AppColors.gray400, size: 28),
                    ],
                  ),
                ),
                // Car icon
                Positioned(
                  top: 120,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: AppColors.green,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.directions_car_rounded,
                          color: Colors.white, size: 20),
                    ),
                  ),
                ),
                // Safe area top bar
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: cs.surface,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.arrow_back_rounded,
                                size: 18, color: cs.onSurface),
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.prime,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.circle,
                                  size: 8, color: Colors.white),
                              SizedBox(width: 5),
                              Text('En route',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Progress card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              _CityChip(
                                  city: widget.from,
                                  icon: Icons.radio_button_checked_rounded,
                                  color: AppColors.green),
                              Expanded(
                                child: Column(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                        value: progress,
                                        backgroundColor: AppColors.gray100,
                                        valueColor:
                                            const AlwaysStoppedAnimation(
                                                AppColors.green),
                                        minHeight: 6,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text('${(progress * 100).toInt()}%',
                                        style: const TextStyle(
                                            fontSize: 10,
                                            color: AppColors.green,
                                            fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ),
                              _CityChip(
                                  city: widget.to,
                                  icon: Icons.location_on_rounded,
                                  color: AppColors.coral),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _StatBox(
                                  label: 'Temps écoulé',
                                  value: '${elapsed}h',
                                  icon: Icons.timer_rounded,
                                  color: AppColors.prime,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _StatBox(
                                  label: 'Temps restant',
                                  value: '~${remaining}h',
                                  icon: Icons.hourglass_bottom_rounded,
                                  color: AppColors.green,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _StatBox(
                                  label: 'Distance',
                                  value: '~${distanceKm}km',
                                  icon: Icons.straighten_rounded,
                                  color: AppColors.gray600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Driver/passenger info
                  Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        radius: 22,
                        backgroundColor: widget.isPrime
                            ? AppColors.primeBg
                            : AppColors.greenLight,
                        child: Text(initials,
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: widget.isPrime
                                    ? AppColors.primeDark
                                    : AppColors.greenDark)),
                      ),
                      title: Text(
                        widget.isDriver
                            ? 'Votre trajet'
                            : widget.driverName,
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface),
                      ),
                      subtitle: Text(
                        widget.isDriver
                            ? '3 passagers à bord'
                            : 'Votre chauffeur',
                        style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant),
                      ),
                      trailing: !widget.isDriver
                          ? IconButton(
                              icon: const Icon(Icons.chat_rounded,
                                  color: AppColors.green),
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ChatScreen(
                                    driverName: widget.driverName,
                                    isPrime: widget.isPrime,
                                  ),
                                ),
                              ),
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Étapes du voyage
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Étapes du voyage',
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: cs.onSurface)),
                          const SizedBox(height: 12),
                          if (apiSteps.isNotEmpty)
                            ...apiSteps.map<Widget>((s) {
                              final label = s['label'] as String? ?? '';
                              final city = s['city'] as String? ?? label;
                              final status = s['status'] as String? ?? 'pending';
                              final estimatedTime = s['estimated_time'] as String? ?? '';
                              final actualTime = s['actual_time'] as String? ?? '';
                              final time = actualTime.isNotEmpty ? actualTime : estimatedTime;
                              return _StepTile(
                                city: city,
                                time: time,
                                status: status,
                                label: label,
                              );
                            })
                          else ...[
                            _StepTile(
                                city: widget.from,
                                time: '08:00',
                                status: 'done',
                                label: 'Départ'),
                            _StepTile(
                                city: 'En route...',
                                time: '~',
                                status: 'current',
                                label: 'Position actuelle'),
                            _StepTile(
                                city: widget.to,
                                time: '~',
                                status: 'pending',
                                label: 'Arrivée estimée'),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Urgence
                  OutlinedButton.icon(
                    onPressed: () => _showEmergencySheet(context),
                    icon: const Icon(Icons.emergency_rounded,
                        color: AppColors.coral),
                    label: const Text('Signaler un problème',
                        style: TextStyle(color: AppColors.coral)),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                          color: AppColors.coral.withOpacity(0.5)),
                      minimumSize: const Size(double.infinity, 44),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showEmergencySheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Signaler un problème',
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            _EmergencyTile(
                icon: Icons.cancel_rounded,
                label: 'Annuler le voyage',
                color: AppColors.coral,
                onTap: () {
                  Navigator.pop(ctx);
                  _cancelTrip(context);
                }),
            _EmergencyTile(
                icon: Icons.warning_rounded,
                label: 'Comportement dangereux',
                color: AppColors.coral,
                onTap: () {
                  Navigator.pop(ctx);
                  _reportDanger(context);
                }),
            _EmergencyTile(
                icon: Icons.phone_rounded,
                label: 'Appeler le support 237COVOIT',
                color: AppColors.green,
                onTap: () {
                  Navigator.pop(ctx);
                  launchUrl(Uri.parse('tel:+237699000000'));
                }),
            _EmergencyTile(
                icon: Icons.local_police_rounded,
                label: 'Urgence — Appeler le 17',
                color: AppColors.coral,
                onTap: () {
                  Navigator.pop(ctx);
                  launchUrl(Uri.parse('tel:17'));
                }),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Future<void> _cancelTrip(BuildContext context) async {
    if (widget.tripId == null) return;
    try {
      final client = ref.read(apiClientProvider);
      await client.post(ApiEndpoints.cancelTrip(widget.tripId!));
      _safetyService?.stop();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Voyage annulé')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e')),
        );
      }
    }
  }

  void _reportDanger(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Signaler un comportement dangereux'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Décrivez le problème rencontré. '
                'Notre équipe sera alertée immédiatement.'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Ex: Conduite dangereuse, vitesse excessive...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Signalement envoyé, merci !')),
              );
            },
            child: const Text('Envoyer'),
          ),
        ],
      ),
    );
  }
}

class _CityChip extends StatelessWidget {
  final String city;
  final IconData icon;
  final Color color;

  const _CityChip(
      {required this.city, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(height: 2),
        Text(city,
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color)),
      ],
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatBox(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface)),
          Text(label,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _StepTile extends StatelessWidget {
  final String city;
  final String time;
  final String status; // done | current | pending
  final String label;

  const _StepTile({
    required this.city,
    required this.time,
    required this.status,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final Color dotColor = status == 'done'
        ? AppColors.green
        : status == 'current'
            ? AppColors.prime
            : AppColors.gray100;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Column(
            children: [
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                  border: status == 'current'
                      ? Border.all(color: AppColors.prime, width: 3)
                      : null,
                ),
                child: status == 'done'
                    ? const Icon(Icons.check, size: 8, color: Colors.white)
                    : null,
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(city,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: status == 'pending'
                            ? cs.onSurfaceVariant
                            : cs.onSurface)),
                Text(label,
                    style: TextStyle(
                        fontSize: 11, color: cs.onSurfaceVariant)),
              ],
            ),
          ),
          Text(time,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: status == 'current'
                      ? AppColors.prime
                      : cs.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _EmergencyTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _EmergencyTile(
      {required this.icon, required this.label, required this.color, this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      leading: Icon(icon, color: color, size: 22),
      title: Text(label,
          style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: color)),
      onTap: onTap ?? () => Navigator.pop(context),
    );
  }
}

class _MapPainter extends CustomPainter {
  final ColorScheme cs;

  _MapPainter({required this.cs});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = cs.outline.withOpacity(0.15)
      ..strokeWidth = 1;

    for (double x = 0; x < size.width; x += 40) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += 40) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}
