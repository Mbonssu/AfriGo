import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../app_theme.dart';
import '../core/constants/api_endpoints.dart';
import '../core/services/media_service.dart';
import '../data/providers/user_providers.dart';
import '../data/providers/auth_providers.dart';
import '../data/providers/journey_providers.dart';
import '../data/repositories/user_repository.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  
  File? _profileImage;
  bool _isLoading = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    final userIdAsync = ref.read(currentUserIdProvider);
    final userId = userIdAsync.valueOrNull;
    
    if (userId != null && userId.isNotEmpty) {
      final profileAsync = ref.read(userProfileProvider(userId));
      final profile = profileAsync.valueOrNull;
      
      if (profile != null) {
        _firstNameController.text = profile.firstName ?? '';
        _lastNameController.text = profile.lastName ?? '';
        _phoneController.text = profile.phone ?? '';
      }
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final mediaService = MediaService();
      final file = await mediaService.pickImage(source: source);
      
      if (file != null) {
        setState(() {
          _profileImage = file;
          _hasChanges = true;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la sélection de l\'image: $e'),
            backgroundColor: AppColors.coral,
          ),
        );
      }
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt_rounded, color: AppColors.green),
                title: const Text('Prendre une photo'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded, color: AppColors.green),
                title: const Text('Choisir depuis la galerie'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.gallery);
                },
              ),
              if (_profileImage != null) ...[
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.delete_rounded, color: AppColors.coral),
                  title: const Text('Supprimer la photo'),
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() {
                      _profileImage = null;
                      _hasChanges = true;
                    });
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final userIdAsync = ref.read(currentUserIdProvider);
      final userId = userIdAsync.valueOrNull;

      if (userId == null || userId.isEmpty) {
        throw Exception('Utilisateur non connecté');
      }

      // Appel API pour mettre à jour le profil
      final userRepo = ref.read(userRepositoryProvider);
      await userRepo.updateProfileWithPhoto(
        userId: userId,
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        phone: _phoneController.text.trim(),
        photo: _profileImage,
      );

      if (mounted) {
        // Invalider le cache du profil pour forcer le rechargement
        ref.invalidate(userProfileProvider(userId));
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Profil mis à jour avec succès'),
            backgroundColor: AppColors.green,
          ),
        );
        
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: AppColors.coral,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userIdAsync = ref.watch(currentUserIdProvider);
    final userId = userIdAsync.valueOrNull;
    final profileAsync = userId != null && userId.isNotEmpty
        ? ref.watch(userProfileProvider(userId))
        : null;
    final profile = profileAsync?.valueOrNull;
    
    final initials = profile?.initials ?? '?';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Modifier mon profil'),
        actions: [
          if (_hasChanges)
            TextButton(
              onPressed: _isLoading ? null : _saveProfile,
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text(
                      'Enregistrer',
                      style: TextStyle(
                        color: AppColors.green,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          onChanged: () {
            if (!_hasChanges) {
              setState(() => _hasChanges = true);
            }
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Photo de profil
              GestureDetector(
                onTap: _showImageSourceDialog,
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.greenLight,
                        border: Border.all(
                          color: AppColors.green.withValues(alpha: 0.3),
                          width: 3,
                        ),
                      ),
                      child: _profileImage != null
                          ? ClipOval(
                              child: Image.file(
                                _profileImage!,
                                fit: BoxFit.cover,
                              ),
                            )
                          : (profile?.profilePictureUrl != null && profile!.profilePictureUrl!.isNotEmpty
                              ? ClipOval(
                                  child: Image.network(
                                    '${ApiEndpoints.gatewayUrl}${profile.profilePictureUrl}',
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Center(
                                        child: Text(
                                          initials,
                                          style: const TextStyle(
                                            fontSize: 40,
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.green,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                )
                              : Center(
                                  child: Text(
                                    initials,
                                    style: const TextStyle(
                                      fontSize: 40,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.green,
                                    ),
                                  ),
                                )),
                    ),
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.green,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                      ),
                      child: const Icon(
                        Icons.camera_alt_rounded,
                        size: 18,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Appuyez pour modifier',
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 32),

              // Formulaire
              TextFormField(
                controller: _firstNameController,
                decoration: const InputDecoration(
                  labelText: 'Prénom',
                  prefixIcon: Icon(Icons.person_outline_rounded),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Le prénom est requis';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _lastNameController,
                decoration: const InputDecoration(
                  labelText: 'Nom',
                  prefixIcon: Icon(Icons.person_outline_rounded),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Le nom est requis';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Téléphone',
                  prefixIcon: Icon(Icons.phone_outlined),
                  border: OutlineInputBorder(),
                  helperText: 'Format: +237XXXXXXXXX',
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Le téléphone est requis';
                  }
                  if (!value.startsWith('+237') || value.length != 13) {
                    return 'Format invalide (+237XXXXXXXXX)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Informations supplémentaires
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.greenLight.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.green.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      size: 20,
                      color: AppColors.green,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Vos informations personnelles sont sécurisées et ne seront partagées qu\'avec les utilisateurs avec qui vous voyagez.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Bouton d'enregistrement (version large en bas)
              if (_hasChanges)
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _isLoading ? null : _saveProfile,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.check_rounded),
                    label: Text(_isLoading ? 'Enregistrement...' : 'Enregistrer les modifications'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.green,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
