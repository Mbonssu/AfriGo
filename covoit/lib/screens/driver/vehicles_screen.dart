import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../app_theme.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client_provider.dart';
import '../../data/models/app_vehicle.dart';
import '../../data/providers/vehicle_providers.dart';

class VehiclesScreen extends ConsumerStatefulWidget {
  const VehiclesScreen({super.key});

  @override
  ConsumerState<VehiclesScreen> createState() => _VehiclesScreenState();
}

class _VehiclesScreenState extends ConsumerState<VehiclesScreen> {
  String? _userId;

  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    final storage = ref.read(tokenStorageProvider);
    final id = await storage.getUserId();
    if (mounted) setState(() => _userId = id);
  }

  @override
  Widget build(BuildContext context) {
    final userId = _userId;

    return Scaffold(
      appBar: AppBar(title: const Text('Mes véhicules')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: userId == null ? null : () => _showAddDialog(userId),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Ajouter'),
        backgroundColor: AppColors.green,
        foregroundColor: Colors.white,
      ),
      body: userId == null
          ? const Center(child: CircularProgressIndicator())
          : _VehicleList(userId: userId),
    );
  }

  Future<void> _showAddDialog(String userId) async {
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _VehicleFormSheet(userId: userId),
    );
    if (created == true) {
      ref.invalidate(vehiclesProvider(userId));
    }
  }
}

class _VehicleList extends ConsumerWidget {
  final String userId;

  const _VehicleList({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehiclesAsync = ref.watch(vehiclesProvider(userId));

    return vehiclesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.coral),
            const SizedBox(height: 12),
            Text('Erreur de chargement', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => ref.invalidate(vehiclesProvider(userId)),
              child: const Text('Réessayer'),
            ),
          ],
        ),
      ),
      data: (vehicles) {
        if (vehicles.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.directions_car_rounded, size: 64, color: Theme.of(context).colorScheme.outline),
                const SizedBox(height: 16),
                Text(
                  'Aucun véhicule enregistré',
                  style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 8),
                Text(
                  'Ajoutez vos véhicules pour les sélectionner\nlors de la publication d\'un trajet.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.outline),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: vehicles.length,
          itemBuilder: (context, index) => _VehicleCard(
            vehicle: vehicles[index],
            userId: userId,
          ),
        );
      },
    );
  }
}

class _VehicleCard extends ConsumerWidget {
  final AppVehicle vehicle;
  final String userId;

  const _VehicleCard({required this.vehicle, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Photos carousel
          if (vehicle.photos.isNotEmpty)
            SizedBox(
              height: 180,
              child: PageView.builder(
                itemCount: vehicle.photos.length,
                itemBuilder: (context, i) {
                  final photo = vehicle.photos[i];
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                        child: Image.network(
                          '${ApiEndpoints.gatewayUrl}${photo.photoUrl}',
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: cs.surfaceContainerHighest,
                            child: const Icon(Icons.broken_image_rounded, size: 40),
                          ),
                        ),
                      ),
                      if (vehicle.photos.length > 1)
                        Positioned(
                          bottom: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${i + 1}/${vehicle.photos.length}',
                              style: const TextStyle(color: Colors.white, fontSize: 12),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            )
          else
            Container(
              height: 120,
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.photo_camera_rounded, size: 32, color: cs.outline),
                    const SizedBox(height: 6),
                    Text('Aucune photo', style: TextStyle(fontSize: 12, color: cs.outline)),
                  ],
                ),
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        vehicle.displayName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: cs.onSurface,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.greenLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${vehicle.seats} places',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.green,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.pin_outlined, size: 15, color: cs.onSurfaceVariant),
                    const SizedBox(width: 6),
                    Text(vehicle.plate, style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
                    if (vehicle.color != null && vehicle.color!.isNotEmpty) ...[
                      const SizedBox(width: 12),
                      Icon(Icons.palette_outlined, size: 15, color: cs.onSurfaceVariant),
                      const SizedBox(width: 6),
                      Text(vehicle.color!, style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
                    ],
                  ],
                ),
                const Divider(height: 20),
                Row(
                  children: [
                    _ActionButton(
                      icon: Icons.add_a_photo_rounded,
                      label: 'Photo',
                      onTap: () => _addPhoto(context, ref),
                    ),
                    const SizedBox(width: 10),
                    _ActionButton(
                      icon: Icons.edit_rounded,
                      label: 'Modifier',
                      onTap: () => _edit(context, ref),
                    ),
                    const Spacer(),
                    _ActionButton(
                      icon: Icons.delete_outline_rounded,
                      label: 'Supprimer',
                      color: AppColors.coral,
                      onTap: () => _delete(context, ref),
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

  Future<void> _addPhoto(BuildContext context, WidgetRef ref) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, maxWidth: 1200, imageQuality: 85);
    if (picked == null) return;

    final repo = ref.read(vehicleRepositoryProvider);
    try {
      final uploadedPhoto = await repo.uploadPhoto(
        userId: userId,
        vehicleId: vehicle.id,
        imageFile: File(picked.path),
        position: vehicle.photos.length,
      );
      ref.invalidate(vehiclesProvider(userId));
      if (context.mounted) {
        final aiStatus = uploadedPhoto.aiStatus;
        final aiReason = uploadedPhoto.aiReason;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              aiStatus == 'review' && aiReason != null && aiReason.isNotEmpty
                  ? 'Photo ajoutée, contrôle requis : $aiReason'
                  : 'Photo ajoutée',
            ),
            backgroundColor: aiStatus == 'review' ? AppColors.prime : AppColors.green,
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

  Future<void> _edit(BuildContext context, WidgetRef ref) async {
    final updated = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _VehicleFormSheet(userId: userId, vehicle: vehicle),
    );
    if (updated == true) {
      ref.invalidate(vehiclesProvider(userId));
    }
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer ce véhicule ?'),
        content: Text('${vehicle.displayName} — ${vehicle.plate}'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Supprimer', style: TextStyle(color: AppColors.coral)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    final repo = ref.read(vehicleRepositoryProvider);
    try {
      await repo.deleteVehicle(userId: userId, vehicleId: vehicle.id);
      ref.invalidate(vehiclesProvider(userId));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Véhicule supprimé'), backgroundColor: AppColors.green),
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

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.green;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: c),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: c)),
          ],
        ),
      ),
    );
  }
}

class _VehicleFormSheet extends ConsumerStatefulWidget {
  final String userId;
  final AppVehicle? vehicle;

  const _VehicleFormSheet({required this.userId, this.vehicle});

  @override
  ConsumerState<_VehicleFormSheet> createState() => _VehicleFormSheetState();
}

class _VehicleFormSheetState extends ConsumerState<_VehicleFormSheet> {
  late final TextEditingController _brandCtrl;
  late final TextEditingController _modelCtrl;
  late final TextEditingController _yearCtrl;
  late final TextEditingController _colorCtrl;
  late final TextEditingController _plateCtrl;
  int _seats = 4;
  bool _saving = false;

  bool get _isEditing => widget.vehicle != null;

  @override
  void initState() {
    super.initState();
    final v = widget.vehicle;
    _brandCtrl = TextEditingController(text: v?.brand ?? '');
    _modelCtrl = TextEditingController(text: v?.model ?? '');
    _yearCtrl = TextEditingController(text: v?.year?.toString() ?? '');
    _colorCtrl = TextEditingController(text: v?.color ?? '');
    _plateCtrl = TextEditingController(text: v?.plate ?? '');
    _seats = v?.seats ?? 4;
  }

  @override
  void dispose() {
    _brandCtrl.dispose();
    _modelCtrl.dispose();
    _yearCtrl.dispose();
    _colorCtrl.dispose();
    _plateCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final brand = _brandCtrl.text.trim();
    final model = _modelCtrl.text.trim();
    final plate = _plateCtrl.text.trim();

    if (brand.isEmpty || model.isEmpty || plate.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Marque, modèle et plaque sont obligatoires.'),
          backgroundColor: AppColors.coral,
        ),
      );
      return;
    }

    // Validation année
    final yearStr = _yearCtrl.text.trim();
    if (yearStr.isNotEmpty) {
      final year = int.tryParse(yearStr);
      final currentYear = DateTime.now().year;
      if (year == null || year < 2005 || year > currentYear + 1) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Année invalide (entre 2005 et ${DateTime.now().year + 1}).'),
            backgroundColor: AppColors.coral,
          ),
        );
        return;
      }
    }
    // Validation plaque (format Cameroun : 2 lettres + 3-5 chiffres + 0-2 lettres)
    final plateClean = plate.replaceAll(RegExp(r'\s+'), '');
    final plateRegex = RegExp(r'^[A-Za-z]{2}\d{3,5}[A-Za-z]{0,2}$');
    if (!plateRegex.hasMatch(plateClean)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Format de plaque invalide. Exemple : LT 1234 AB'),
          backgroundColor: AppColors.coral,
        ),
      );
      return;
    }
    // Validation places
    if (_seats < 2 || _seats > 9) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Le véhicule doit avoir entre 2 et 9 places.'),
          backgroundColor: AppColors.coral,
        ),
      );
      return;
    }

    setState(() => _saving = true);
    final repo = ref.read(vehicleRepositoryProvider);
    try {
      if (_isEditing) {
        await repo.updateVehicle(
          userId: widget.userId,
          vehicleId: widget.vehicle!.id,
          brand: brand,
          model: model,
          year: int.tryParse(_yearCtrl.text.trim()),
          color: _colorCtrl.text.trim().isNotEmpty ? _colorCtrl.text.trim() : null,
          plate: plate,
          seats: _seats,
        );
      } else {
        await repo.createVehicle(
          userId: widget.userId,
          brand: brand,
          model: model,
          year: int.tryParse(_yearCtrl.text.trim()),
          color: _colorCtrl.text.trim().isNotEmpty ? _colorCtrl.text.trim() : null,
          plate: plate,
          seats: _seats,
        );
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e'), backgroundColor: AppColors.coral),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
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
            const SizedBox(height: 16),
            Text(
              _isEditing ? 'Modifier le véhicule' : 'Ajouter un véhicule',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: cs.onSurface),
            ),
            const SizedBox(height: 20),
            _Field(controller: _brandCtrl, label: 'Marque *', hint: 'Ex : Toyota', icon: Icons.directions_car_rounded),
            const SizedBox(height: 12),
            _Field(controller: _modelCtrl, label: 'Modèle *', hint: 'Ex : Corolla', icon: Icons.car_repair_rounded),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _Field(controller: _yearCtrl, label: 'Année', hint: '2022', icon: Icons.calendar_today_rounded, keyboardType: TextInputType.number)),
                const SizedBox(width: 12),
                Expanded(child: _Field(controller: _colorCtrl, label: 'Couleur', hint: 'Blanc', icon: Icons.palette_outlined)),
              ],
            ),
            const SizedBox(height: 12),
            _Field(controller: _plateCtrl, label: 'Plaque *', hint: 'LT 1234 AB', icon: Icons.pin_outlined),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.airline_seat_recline_normal_rounded, size: 20, color: cs.onSurfaceVariant),
                const SizedBox(width: 10),
                Expanded(child: Text('Nombre de places', style: TextStyle(fontSize: 14, color: cs.onSurface))),
                IconButton(
                  onPressed: _seats > 1 ? () => setState(() => _seats--) : null,
                  icon: Icon(Icons.remove_circle_outline_rounded, color: _seats > 1 ? AppColors.green : cs.outline),
                  iconSize: 22,
                ),
                Text('$_seats', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: cs.onSurface)),
                IconButton(
                  onPressed: _seats < 8 ? () => setState(() => _seats++) : null,
                  icon: Icon(Icons.add_circle_outline_rounded, color: _seats < 8 ? AppColors.green : cs.outline),
                  iconSize: 22,
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Icon(_isEditing ? Icons.check_rounded : Icons.add_rounded),
                label: Text(_saving ? 'Enregistrement...' : (_isEditing ? 'Mettre à jour' : 'Ajouter le véhicule')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;

  const _Field({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 20),
      ),
    );
  }
}
