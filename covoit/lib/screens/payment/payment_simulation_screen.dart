import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';

import '../../app_theme.dart';
import 'escrow_status_screen.dart';

/// Écran de simulation de paiement
/// Simule le processus de paiement sans vraie intégration bancaire
class PaymentSimulationScreen extends ConsumerStatefulWidget {
  final String bookingId;
  final double amount;
  final String paymentMethod;
  final String tripTitle;

  const PaymentSimulationScreen({
    super.key,
    required this.bookingId,
    required this.amount,
    required this.paymentMethod,
    required this.tripTitle,
  });

  @override
  ConsumerState<PaymentSimulationScreen> createState() =>
      _PaymentSimulationScreenState();
}

class _PaymentSimulationScreenState
    extends ConsumerState<PaymentSimulationScreen> {
  bool _isProcessing = false;
  String _status = 'waiting'; // waiting, processing, success, failed

  String get _methodName {
    switch (widget.paymentMethod) {
      case 'mtn':
        return 'MTN Mobile Money';
      case 'orange':
        return 'Orange Money';
      default:
        return 'Mobile Money';
    }
  }

  Color get _methodColor {
    switch (widget.paymentMethod) {
      case 'mtn':
        return const Color(0xFFFFCC00);
      case 'orange':
        return const Color(0xFFFF6600);
      default:
        return AppColors.green;
    }
  }

  Future<void> _simulatePayment() async {
    setState(() {
      _isProcessing = true;
      _status = 'processing';
    });

    // Simulation : attendre 3 secondes
    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;

    setState(() {
      _status = 'success';
      _isProcessing = false;
    });

    // Attendre 1 seconde puis naviguer vers l'écran de séquestre
    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => EscrowStatusScreen(
          bookingId: widget.bookingId,
          amount: widget.amount,
          tripTitle: widget.tripTitle,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Paiement'),
        automaticallyImplyLeading: _status == 'waiting',
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 20),

            // Icône de statut
            _buildStatusIcon(),
            const SizedBox(height: 24),

            // Message de statut
            _buildStatusMessage(cs),
            const SizedBox(height: 32),

            // Détails du paiement
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  _DetailRow(
                    label: 'Montant',
                    value: '${widget.amount.toStringAsFixed(0)} FCFA',
                    isHighlighted: true,
                  ),
                  const Divider(height: 24),
                  _DetailRow(
                    label: 'Méthode',
                    value: _methodName,
                  ),
                  const Divider(height: 24),
                  _DetailRow(
                    label: 'Trajet',
                    value: widget.tripTitle,
                  ),
                  const Divider(height: 24),
                  _DetailRow(
                    label: 'Réservation',
                    value: '#${widget.bookingId.substring(0, 8)}',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Bouton d'action
            if (_status == 'waiting') ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _simulatePayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _methodColor,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Payer maintenant'),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Annuler'),
              ),
            ],

            // Info simulation
            if (_status == 'waiting')
              Container(
                margin: const EdgeInsets.only(top: 24),
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
                        'Mode simulation : Aucun paiement réel ne sera effectué',
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
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIcon() {
    switch (_status) {
      case 'processing':
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: _methodColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: SizedBox(
            width: 60,
            height: 60,
            child: CircularProgressIndicator(
              strokeWidth: 4,
              valueColor: AlwaysStoppedAnimation(_methodColor),
            ),
          ),
        );
      case 'success':
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.greenLight,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check_circle_rounded,
            size: 60,
            color: AppColors.green,
          ),
        );
      case 'failed':
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.coralLight,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.error_rounded,
            size: 60,
            color: AppColors.coral,
          ),
        );
      default:
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: _methodColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.payment_rounded,
            size: 60,
            color: _methodColor,
          ),
        );
    }
  }

  Widget _buildStatusMessage(ColorScheme cs) {
    switch (_status) {
      case 'processing':
        return Column(
          children: [
            Text(
              'Traitement en cours...',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Veuillez patienter pendant que nous traitons votre paiement',
              style: TextStyle(
                fontSize: 14,
                color: cs.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        );
      case 'success':
        return Column(
          children: [
            Text(
              'Paiement réussi !',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.green,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Vos fonds sont maintenant en séquestre',
              style: TextStyle(
                fontSize: 14,
                color: cs.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        );
      default:
        return Column(
          children: [
            Text(
              'Confirmer le paiement',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Vérifiez les détails avant de continuer',
              style: TextStyle(
                fontSize: 14,
                color: cs.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        );
    }
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isHighlighted;

  const _DetailRow({
    required this.label,
    required this.value,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: cs.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isHighlighted ? 18 : 14,
            fontWeight: isHighlighted ? FontWeight.w700 : FontWeight.w600,
            color: isHighlighted ? cs.primary : cs.onSurface,
          ),
        ),
      ],
    );
  }
}
