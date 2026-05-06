import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

import '../../app_theme.dart';
import '../../core/services/media_service.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client_provider.dart';

/// Écran d'ajout de véhicule avec photos obligatoires
class AddVehicleScreen extends ConsumerStatefulWidget {
  final String userId;

  const AddVehicleScreen({
    super.key,
    required this.userId,
  });

  @override
  ConsumerState<AddVehicleScreen> createState() => _AddVehicleScreenState();
}

class _AddVehicleScreenState extends ConsumerState<AddVehicleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _mediaService = MediaService();

  // Controllers
  final _brandCtrl = TextEditingController();
  final _modelCtrl = TextEditingController();
  final _yearCtrl = TextEditingController();
  final _colorCtrl = TextEditingController();
  final _plateCtrl = TextEditingController();
  final _seatsCtrl = TextEditingController(text: '4');

  // Photos
  File? _registrationCardPhoto; // Photo de la carte grise
  final List<File> _vehiclePhotos = []; // Photos du véhicule (max 5)

  bool _isLoading = false;

  @override
  void dispose() {
    _brandCtrl.dispose();
    _modelCtrl.dispose();
    _yearCtrl.dispose();
    _colorCtrl.dispose();
    _plateCtrl.dispose();
    _seatsCtrl.dispose();
    super.dispose();
  }

  Future<void> _takeRegistrationCardPhoto() async {
    final photo = await _mediaService.showPhotoSourceDialog(
      context,
      title: 'Photo de la carte grise',
    );

    if (photo != null) {
      setState(() => _registrationCardPhoto = photo);
    }
  }

  Future<void> _addVehiclePhoto() async {
    if (_vehiclePhotos.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Maximum 5 photos du véhicule'),
          backgroundColor: AppColors.coral,
        ),
      );
      return;
    }

    final photo = await _mediaService.showPhotoSourceDialog(
      context,
      title: 'Photo du véhicule',
    );

    if (photo != null) {
      setState(() => _vehiclePhotos.add(photo));
    }
  }

  void _removeVehiclePhoto(int index) {
    setState(() => _vehiclePhotos.removeAt(index));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    // Vérifier les photos obligatoires
    if (_registrationCardPhoto == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La photo de la carte grise est obligatoire'),
          backgroundColor: AppColors.coral,
        ),
      );
      return;
    }

    if (_vehiclePhotos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Au moins une photo du véhicule est requise'),
          backgroundColor: AppColors.coral,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final apiClient = ref.read(apiClientProvider);

      // Préparer le FormData
      final formData = FormData.fromMap({
        'brand': _brandCtrl.text.trim(),
        'model': _modelCtrl.text.trim(),
        'year': int.parse(_yearCtrl.text.trim()),
        'color': _colorCtrl.text.trim(),
        'license_plate': _plateCtrl.text.trim().toUpperCase(),
        'seats': int.parse(_seatsCtrl.text.trim()),
        'registration_card_photo': await MultipartFile.fromFile(
          _registrationCardPhoto!.path,
          filename: 'registration_card.jpg',
        ),
      });

      // Ajouter les photos du véhicule
      for (int i = 0; i < _vehiclePhotos.length; i++) {
        formData.files.add(MapEntry(
          'vehicle_photos',
          await MultipartFile.fromFile(
            _vehiclePhotos[i].path,
            filename: 'vehicle_$i.jpg',
          ),
        ));
      }

      // Envoyer au backend
      await apiClient.uploadFile(
        ApiEndpoints.vehicles(widget.userId),
        formData: formData,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Véhicule ajouté avec succès !'),
          backgroundColor: AppColors.green,
        ),
      );

      Navigator.pop(context, true); // Retour avec succès
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.toString()}'),
          backgroundColor: AppColors.coral,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajouter un véhicule'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primeBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.prime.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded,
                        size: 18, color: AppColors.prime),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Photos obligatoires : carte grise + au moins 1 photo du véhicule',
                        style: TextStyle(
                          fontSize: 12,
                          color: cs.onSurfaceVariant,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Photo de la carte grise
              Text(
                'Photo de la carte grise *',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              _RegistrationCardPhotoWidget(
                photo: _registrationCardPhoto,
                onTap: _takeRegistrationCardPhoto,
                onRemove: () => setState(() => _registrationCardPhoto = null),
              ),
              const SizedBox(height: 24),

              // Photos du véhicule
              Text(
                'Photos du véhicule * (max 5)',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              _VehiclePhotosWidget(
                photos: _vehiclePhotos,
                onAdd: _addVehiclePhoto,
                onRemove: _removeVehiclePhoto,
              ),
              const SizedBox(height: 24),

              // Marque
              Text(
                'Marque *',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _brandCtrl,
                decoration: const InputDecoration(
                  hintText: 'Toyota, Mercedes, etc.',
                  prefixIcon: Icon(Icons.directions_car_rounded, size: 20),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Entrez la marque';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Modèle
              Text(
                'Modèle *',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _modelCtrl,
                decoration: const InputDecoration(
                  hintText: 'Corolla, C-Class, etc.',
                  prefixIcon: Icon(Icons.car_rental_rounded, size: 20),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Entrez le modèle';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Année et Couleur
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Année *',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: cs.onSurface,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _yearCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            hintText: '2020',
                            prefixIcon: Icon(Icons.calendar_today_rounded, size: 20),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Année requise';
                            }
                            final year = int.tryParse(value);
                            if (year == null || year < 1990 || year > DateTime.now().year + 1) {
                              return 'Année invalide';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Couleur *',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: cs.onSurface,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _colorCtrl,
                          decoration: const InputDecoration(
                            hintText: 'Blanc',
                            prefixIcon: Icon(Icons.palette_rounded, size: 20),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Couleur requise';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Plaque et Sièges
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Plaque d\'immatriculation *',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: cs.onSurface,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _plateCtrl,
                          textCapitalization: TextCapitalization.characters,
                          decoration: const InputDecoration(
                            hintText: 'ABC-1234-XY',
                            prefixIcon: Icon(Icons.pin_rounded, size: 20),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Plaque requise';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Places *',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: cs.onSurface,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _seatsCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            hintText: '4',
                            prefixIcon: Icon(Icons.event_seat_rounded, size: 20),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Requis';
                            }
                            final seats = int.tryParse(value);
                            if (seats == null || seats < 1 || seats > 8) {
                              return 'Invalide';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Bouton soumettre
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Ajouter le véhicule'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Widget pour la photo de la carte grise
class _RegistrationCardPhotoWidget extends StatelessWidget {
  final File? photo;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _RegistrationCardPhotoWidget({
    required this.photo,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (photo == null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 150,
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: cs.outline.withOpacity(0.3),
              style: BorderStyle.solid,
              width: 2,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_a_photo_rounded, size: 48, color: cs.primary),
              const SizedBox(height: 8),
              Text(
                'Ajouter la photo',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Carte grise lisible',
                style: TextStyle(
                  fontSize: 12,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(
            photo,
            height: 150,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: IconButton(
            onPressed: onRemove,
            icon: const Icon(Icons.close_rounded),
            style: IconButton.styleFrom(
              backgroundColor: Colors.black54,
              foregroundColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}

// Widget pour les photos du véhicule
class _VehiclePhotosWidget extends StatelessWidget {
  final List<File> photos;
  final VoidCallback onAdd;
  final void Function(int) onRemove;

  const _VehiclePhotosWidget({
    required this.photos,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        // Photos existantes
        ...photos.asMap().entries.map((entry) {
          final index = entry.key;
          final photo = entry.value;
          return Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  photo,
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: 4,
                right: 4,
                child: IconButton(
                  onPressed: () => onRemove(index),
                  icon: const Icon(Icons.close_rounded, size: 18),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black54,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(4),
                    minimumSize: const Size(28, 28),
                  ),
                ),
              ),
            ],
          );
        }).toList(),

        // Bouton ajouter
        if (photos.length < 5)
          InkWell(
            onTap: onAdd,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: cs.outline.withOpacity(0.3),
                  style: BorderStyle.solid,
                  width: 2,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_rounded, size: 32, color: cs.primary),
                  const SizedBox(height: 4),
                  Text(
                    'Ajouter',
                    style: TextStyle(
                      fontSize: 11,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
