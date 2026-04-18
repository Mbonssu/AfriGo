import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../app_theme.dart';
import '../../data/providers/journey_providers.dart';

/// Écran "Carte d'embarquement" pour le passager.
///
/// Affiche le code PIN 4 chiffres en gros + un QR code contenant le même code.
/// Le passager montre cet écran au chauffeur qui scanne le QR ou saisit le PIN.
class BoardingPassScreen extends ConsumerStatefulWidget {
  final String bookingId;
  final String tripFrom;
  final String tripTo;

  const BoardingPassScreen({
    super.key,
    required this.bookingId,
    required this.tripFrom,
    required this.tripTo,
  });

  @override
  ConsumerState<BoardingPassScreen> createState() => _BoardingPassScreenState();
}

class _BoardingPassScreenState extends ConsumerState<BoardingPassScreen> {
  Map<String, dynamic>? _data;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadBoardingCode();
  }

  Future<void> _loadBoardingCode() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = ref.read(journeyRepositoryProvider);
      final data = await repo.getBoardingCode(widget.bookingId);
      if (!mounted) return;
      setState(() {
        _data = data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final isDark = cs.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Carte d\'embarquement'),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError()
              : _buildPass(cs, tt, isDark),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.coral),
            const SizedBox(height: 12),
            Text(
              _error ?? 'Erreur inconnue',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.coral),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _loadBoardingCode,
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPass(ColorScheme cs, TextTheme tt, bool isDark) {
    final code = _data?['boarding_code'] as String? ?? '----';
    final isBoarded = _data?['is_boarded'] as bool? ?? false;

    // Données encodées dans le QR : booking_id:code
    final qrData = '${widget.bookingId}:$code';

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        children: [
          // ── Trajet ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.green,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Text(
                  widget.tripFrom,
                  style: tt.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 6),
                  child: Icon(Icons.arrow_downward_rounded,
                      color: Colors.white70, size: 28),
                ),
                Text(
                  widget.tripTo,
                  style: tt.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ── Statut embarquement ──
          if (isBoarded)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.greenLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.green),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, color: AppColors.green),
                  SizedBox(width: 8),
                  Text(
                    'Embarquement confirmé !',
                    style: TextStyle(
                      color: AppColors.greenDark,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),

          if (!isBoarded) ...[
            // ── Code PIN ──
            Text(
              'Votre code d\'embarquement',
              style: tt.bodyLarge?.copyWith(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.dark600 : AppColors.gray50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.green.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: Text(
                code.split('').join('  '),
                style: tt.displayLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 8,
                  color: AppColors.green,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Donnez ce code au chauffeur',
              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),

            const SizedBox(height: 24),

            // ── Séparateur ──
            Row(
              children: [
                Expanded(child: Divider(color: cs.outlineVariant)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text('ou', style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                ),
                Expanded(child: Divider(color: cs.outlineVariant)),
              ],
            ),

            const SizedBox(height: 24),

            // ── QR Code ──
            Text(
              'Montrez ce QR code au chauffeur',
              style: tt.bodyLarge?.copyWith(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: QrImageView(
                data: qrData,
                version: QrVersions.auto,
                size: 200,
                eyeStyle: const QrEyeStyle(
                  eyeShape: QrEyeShape.square,
                  color: AppColors.greenDark,
                ),
                dataModuleStyle: const QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square,
                  color: AppColors.green,
                ),
              ),
            ),

            const SizedBox(height: 32),

            // ── Info ──
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primeBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.primeDark, size: 20),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Le chauffeur vérifiera votre code à chaque point de ramassage pour confirmer votre embarquement.',
                      style: TextStyle(
                        color: AppColors.primeDark,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
