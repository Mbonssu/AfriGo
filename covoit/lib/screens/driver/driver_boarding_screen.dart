import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../app_theme.dart';
import '../../data/providers/journey_providers.dart';

/// Écran de vérification d'embarquement côté chauffeur.
///
/// Deux modes :
/// 1. Scanner le QR code du passager
/// 2. Saisir manuellement le code PIN 4 chiffres
class DriverBoardingVerifyScreen extends ConsumerStatefulWidget {
  final String bookingId;
  final String passengerName;

  const DriverBoardingVerifyScreen({
    super.key,
    required this.bookingId,
    required this.passengerName,
  });

  @override
  ConsumerState<DriverBoardingVerifyScreen> createState() =>
      _DriverBoardingVerifyScreenState();
}

class _DriverBoardingVerifyScreenState
    extends ConsumerState<DriverBoardingVerifyScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _pinController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _verifying = false;
  bool _verified = false;
  String? _error;
  bool _scanProcessed = false;
  int _attemptCount = 0;
  bool _blocked = false;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _verify(String code, String method) async {
    if (_verifying || _verified) return;
    if (_blocked) {
      setState(() => _error = 'Trop de tentatives. Réessayez dans 5 minutes.');
      return;
    }
    setState(() {
      _verifying = true;
      _error = null;
    });
    try {
      final repo = ref.read(journeyRepositoryProvider);
      await repo.verifyBoarding(
        bookingId: widget.bookingId,
        code: code,
        method: method,
      );
      if (!mounted) return;
      setState(() {
        _verified = true;
        _verifying = false;
      });
      // Vibrer pour feedback
      HapticFeedback.heavyImpact();
    } catch (e) {
      if (!mounted) return;
      _attemptCount++;
      if (_attemptCount >= 3) {
        setState(() {
          _blocked = true;
          _error = 'Trop de tentatives. Accès bloqué 5 minutes.';
          _verifying = false;
          _scanProcessed = false;
        });
        Future.delayed(const Duration(minutes: 5), () {
          if (mounted) {
            setState(() {
              _blocked = false;
              _attemptCount = 0;
            });
          }
        });
      } else {
        setState(() {
          _error = 'Code incorrect. Tentative $_attemptCount/3.';
          _verifying = false;
          _scanProcessed = false;
        });
          HapticFeedback.vibrate();
        }
      }
  }

  void _onQrDetected(BarcodeCapture capture) {
    if (_scanProcessed || _verified) return;
    final barcode = capture.barcodes.firstOrNull;
    if (barcode == null || barcode.rawValue == null) return;

    final raw = barcode.rawValue!;
    // Format attendu : "booking_id:code" (4 chiffres)
    final parts = raw.split(':');
    String code;
    if (parts.length == 2 && parts[1].length == 4) {
      // Vérifier que c'est bien le bon booking
      if (parts[0] != widget.bookingId) {
        setState(() => _error = 'Ce QR ne correspond pas à ce passager');
        return;
      }
      code = parts[1];
    } else if (raw.length == 4 && RegExp(r'^\d{4}$').hasMatch(raw)) {
      code = raw;
    } else {
      setState(() => _error = 'QR code invalide');
      return;
    }

    _scanProcessed = true;
    _verify(code, 'qr');
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    if (_verified) {
      return Scaffold(
        body: _buildSuccess(cs, tt),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Vérifier ${widget.passengerName}'),
        bottom: TabBar(
          controller: _tabCtrl,
          tabs: const [
            Tab(icon: Icon(Icons.qr_code_scanner), text: 'Scanner QR'),
            Tab(icon: Icon(Icons.dialpad), text: 'Saisir PIN'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _buildScannerTab(cs, tt),
          _buildPinTab(cs, tt),
        ],
      ),
    );
  }

  Widget _buildSuccess(ColorScheme cs, TextTheme tt) {
    return SafeArea(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: const BoxDecoration(
                color: AppColors.greenLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                color: AppColors.green,
                size: 56,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Passager vérifié !',
              style: tt.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.green,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.passengerName,
              style: tt.titleMedium?.copyWith(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () => Navigator.pop(context, true),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Retour aux passagers'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.green,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScannerTab(ColorScheme cs, TextTheme tt) {
    return Column(
      children: [
        if (_error != null)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.coralLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: AppColors.coral, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _error!,
                    style: const TextStyle(color: AppColors.coral, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        Expanded(
          child: Stack(
            alignment: Alignment.center,
            children: [
              MobileScanner(onDetect: _onQrDetected),
              // Overlay carré guide
              Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.green, width: 3),
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              if (_verifying)
                Container(
                  color: Colors.black54,
                  child: const Center(
                    child: CircularProgressIndicator(color: AppColors.green),
                  ),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Scannez le QR code affiché sur le téléphone du passager',
            textAlign: TextAlign.center,
            style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
          ),
        ),
      ],
    );
  }

  Widget _buildPinTab(ColorScheme cs, TextTheme tt) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            const SizedBox(height: 24),

            Icon(
              Icons.dialpad_rounded,
              size: 64,
              color: cs.onSurfaceVariant.withValues(alpha: 0.4),
            ),

            const SizedBox(height: 24),

            Text(
              'Demandez le code au passager',
              style: tt.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 8),
            Text(
              'Le passager vous donne son code PIN 4 chiffres',
              style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 32),

            TextFormField(
              controller: _pinController,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              maxLength: 4,
              style: tt.headlineLarge?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: 16,
              ),
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                counterText: '',
                hintText: '• • • •',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.green, width: 2),
                ),
              ),
              validator: (v) {
                if (v == null || v.length != 4) return 'Code à 4 chiffres';
                return null;
              },
            ),

            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: const TextStyle(color: AppColors.coral),
              ),
            ],

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton.icon(
                onPressed: _verifying
                    ? null
                    : () {
                        if (_formKey.currentState?.validate() ?? false) {
                          _verify(_pinController.text, 'pin');
                        }
                      },
                icon: _verifying
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.verified_user),
                label: Text(_verifying ? 'Vérification...' : 'Vérifier'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
