import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../app_theme.dart';
import '../core/constants/api_endpoints.dart';
import '../core/network/api_client_provider.dart';
import '../data/providers/user_providers.dart';
import '../data/providers/journey_providers.dart';

class IdentityVerificationScreen extends ConsumerStatefulWidget {
  const IdentityVerificationScreen({super.key});

  @override
  ConsumerState<IdentityVerificationScreen> createState() =>
      _IdentityVerificationScreenState();
}

class _IdentityVerificationScreenState
    extends ConsumerState<IdentityVerificationScreen> {
  File? _cniPhoto;
  File? _selfiePhoto;
  bool _isVerifying = false;
  Map<String, dynamic>? _result;
  String? _error;
  String _docType = 'CNI';
  final _docNumberCtrl = TextEditingController();

  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _docNumberCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickCNI() async {
    final picked = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1920,
      imageQuality: 85,
    );
    if (picked != null) {
      setState(() {
        _cniPhoto = File(picked.path);
        _result = null;
        _error = null;
      });
    }
  }

  Future<void> _pickSelfie() async {
    final picked = await _picker.pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.front,
      maxWidth: 1920,
      imageQuality: 85,
    );
    if (picked != null) {
      setState(() {
        _selfiePhoto = File(picked.path);
        _result = null;
        _error = null;
      });
    }
  }

  Future<void> _verify() async {
    if (_cniPhoto == null || _selfiePhoto == null) return;

    final docNumber = _docNumberCtrl.text.trim();
    if (docNumber.isEmpty) {
      setState(() => _error = "Veuillez saisir le numéro de votre pièce d'identité.");
      return;
    }
    if (docNumber.length < 6 || docNumber.length > 20) {
      setState(() => _error = 'Numéro de pièce invalide (6 à 20 caractères).');
      return;
    }

    setState(() {
      _isVerifying = true;
      _error = null;
      _result = null;
    });

    try {
      final userId = await ref.read(currentUserIdProvider.future);
      if (userId == null || userId.isEmpty) {
        throw Exception('Utilisateur non connecté');
      }

      final client = ref.read(apiClientProvider);
      final formData = FormData.fromMap({
        'cni_photo': await MultipartFile.fromFile(
          _cniPhoto!.path,
          filename: 'cni.jpg',
        ),
        'selfie': await MultipartFile.fromFile(
          _selfiePhoto!.path,
          filename: 'selfie.jpg',
        ),
        'doc_type': _docType,
        'doc_number': docNumber,
      });

      final response = await client.uploadFile<Map<String, dynamic>>(
        ApiEndpoints.verifyKYC(userId),
        formData: formData,
      );

      ref.read(userRepositoryProvider).invalidateCache();
      ref.invalidate(userProfileProvider(userId));

      setState(() {
        _result = response;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      setState(() => _isVerifying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray50,
      appBar: AppBar(
        title: const Text("Vérification d'identité"),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.dark900,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.greenLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.shield_rounded, color: AppColors.green, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Prenez en photo votre CNI camerounaise (ancien ou nouveau modèle) puis un selfie pour vérifier votre identité.',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.greenDark,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            DropdownButtonFormField<String>(
              value: _docType,
              decoration: const InputDecoration(
                labelText: "Type de pièce d'identité",
                prefixIcon: Icon(Icons.badge_rounded),
              ),
              items: const [
                DropdownMenuItem(value: 'CNI', child: Text("Carte Nationale d'Identité")),
                DropdownMenuItem(value: 'PASSEPORT', child: Text('Passeport')),
                DropdownMenuItem(value: 'SEJOUR', child: Text('Titre de séjour')),
              ],
              onChanged: (v) => setState(() => _docType = v ?? 'CNI'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _docNumberCtrl,
              decoration: const InputDecoration(
                labelText: 'Numéro de la pièce *',
                hintText: 'Ex : 1234567890123456',
                prefixIcon: Icon(Icons.numbers_rounded),
              ),
              textCapitalization: TextCapitalization.characters,
              onChanged: (_) => setState(() => _error = null),
            ),

            const SizedBox(height: 24),

            _buildStep(
              number: '1',
              title: 'Photo de la CNI',
              subtitle: 'Ancien ou nouveau modèle',
              icon: Icons.credit_card_rounded,
              file: _cniPhoto,
              onTap: _pickCNI,
            ),

            const SizedBox(height: 16),

            _buildStep(
              number: '2',
              title: 'Selfie',
              subtitle: 'Caméra frontale, visage dégagé',
              icon: Icons.face_rounded,
              file: _selfiePhoto,
              onTap: _pickSelfie,
            ),

            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: (_cniPhoto != null && _selfiePhoto != null && !_isVerifying)
                  ? _verify
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isVerifying
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Vérifier mon identité',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
            ),

            if (_error != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.coralLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _error!,
                  style: const TextStyle(color: AppColors.coral, fontSize: 13),
                ),
              ),
            ],

            if (_result != null) ...[
              const SizedBox(height: 20),
              _buildResultCard(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStep({
    required String number,
    required String title,
    required String subtitle,
    required IconData icon,
    File? file,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: file != null ? AppColors.green : AppColors.gray100,
            width: file != null ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: file != null ? AppColors.green : AppColors.gray100,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: file != null
                    ? const Icon(Icons.check, color: Colors.white, size: 20)
                    : Text(
                        number,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.gray600,
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
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: AppColors.dark900,
                    ),
                  ),
                  Text(
                    file != null ? 'Photo prise ✓' : subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: file != null ? AppColors.green : AppColors.gray400,
                    ),
                  ),
                ],
              ),
            ),
            Icon(icon, color: AppColors.gray400, size: 28),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard() {
    final status = _result!['kyc_status'] ?? '';
    final isVerified = status == 'verified';
    final isPending = status == 'pending';
    final cniValidation = _result!['cni_image_validation'] is Map
      ? Map<String, dynamic>.from(_result!['cni_image_validation'] as Map)
      : null;
    final selfieValidation = _result!['selfie_image_validation'] is Map
      ? Map<String, dynamic>.from(_result!['selfie_image_validation'] as Map)
      : null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isVerified
            ? AppColors.greenLight
            : isPending
                ? AppColors.primeBg
                : AppColors.coralLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isVerified
                    ? Icons.verified_rounded
                    : isPending
                        ? Icons.hourglass_bottom_rounded
                        : Icons.cancel_rounded,
                color: isVerified
                    ? AppColors.green
                    : isPending
                        ? AppColors.prime
                        : AppColors.coral,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                isVerified
                    ? 'Identité vérifiée !'
                    : isPending
                        ? 'Vérification en cours'
                        : 'Vérification échouée',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: isVerified
                      ? AppColors.greenDark
                      : isPending
                          ? AppColors.primeDark
                          : AppColors.coral,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_result!['cni_type'] != null && _result!['cni_type'] != '')
            _infoRow('Type CNI', _result!['cni_type'] == 'nouveau' ? 'Nouveau modèle' : 'Ancien modèle'),
          if (_result!['cni_number'] != null && _result!['cni_number'] != '')
            _infoRow('N° CNI', _result!['cni_number']),
          if (_result!['cni_nom'] != null && _result!['cni_nom'] != '')
            _infoRow('Nom', _result!['cni_nom']),
          if (_result!['cni_prenom'] != null && _result!['cni_prenom'] != '')
            _infoRow('Prénom', _result!['cni_prenom']),
          if (_result!['face_confidence'] != null)
            _infoRow('Correspondance visage', '${(_result!['face_confidence'] * 100).toStringAsFixed(0)}%'),
          if (cniValidation != null && cniValidation['status'] != 'accepted')
            _infoRow(
              'Contrôle photo CNI',
              cniValidation['reason']?.toString() ?? 'Contrôle manuel requis',
            ),
          if (selfieValidation != null && selfieValidation['status'] != 'accepted')
            _infoRow(
              'Contrôle selfie',
              selfieValidation['reason']?.toString() ?? 'Contrôle manuel requis',
            ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text('$label : ', style: const TextStyle(fontSize: 13, color: AppColors.gray600)),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.dark900),
            ),
          ),
        ],
      ),
    );
  }
}
