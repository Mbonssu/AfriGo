import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';

import '../../app_theme.dart';

/// Écran de libération des fonds (Client/Passager)
/// Le client clique sur "Déposer" pour libérer les fonds du séquestre vers le chauffeur
class ReleaseFundsScreen extends ConsumerStatefulWidget {
  final String bookingId;
  final double amount;
  final String tripTitle;
  final String driverName;

  const ReleaseFundsScreen({
    super.key,
    required this.bookingId,
    required this.amount,
    required this.tripTitle,
    required this.driverName,
  });

  @override
  ConsumerState<ReleaseFundsScreen> createState() => _ReleaseFundsScreenState();
}

class _ReleaseFundsScreenState extends ConsumerState<ReleaseFundsScreen> {
  bool _isProcessing = false;
  bool _isReleased = false;

  Future<void> _releaseFunds() async {
    // Confirmation
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la libération'),
        content: Text(
          'Êtes-vous sûr de vouloir libérer ${widget.amount.toStringAsFixed(0)} FCFA vers ${widget.driverName} ?\n\nCette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isProcessing = true);

    // Simulation : attendre 2 secondes
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    setState(() {
      _isProcessing = false;
      _isReleased = true;
    });

    // Afficher le message de succès
    _showSuccessDialog();
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AppColors.greenLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                size: 60,
                color: AppColors.green,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Fonds libérés !',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Les fonds ont été transférés vers le compte de ${widget.driverName}.',
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primeBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.info_outline_rounded,
                      size: 16, color: AppColors.prime),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Mode simulation : Aucun transfert réel',
                      style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Fermer le dialogue
              Navigator.popUntil(context, (route) => route.isFirst); // Retour à l'accueil
            },
            child: const Text('Terminer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Validation du trajet'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 20),

            // Icône
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _isReleased
                    ? AppColors.greenLight
                    : AppColors.primeBg,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _isReleased
                    ? Icons.check_circle_rounded
                    : Icons.lock_open_rounded,
                size: 60,
                color: _isReleased ? AppColors.green : AppColors.prime,
              ),
            ),
            const SizedBox(height: 24),

            // Titre
            Text(
              _isReleased
                  ? 'Fonds libérés avec succès'
                  : 'Libérer les fonds',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _isReleased
                  ? 'Le chauffeur a reçu le paiement'
                  : 'Le trajet est terminé. Libérez les fonds pour le chauffeur.',
              style: TextStyle(
                fontSize: 14,
                color: cs.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Détails
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  _DetailRow(
                    icon: Icons.person_rounded,
                    label: 'Chauffeur',
                    value: widget.driverName,
                  ),
                  const Divider(height: 24),
                  _DetailRow(
                    icon: Icons.route_rounded,
                    label: 'Trajet',
                    value: widget.tripTitle,
                  ),
                  const Divider(height: 24),
                  _DetailRow(
                    icon: Icons.payments_rounded,
                    label: 'Montant',
                    value: '${widget.amount.toStringAsFixed(0)} FCFA',
                    valueColor: AppColors.green,
                  ),
                  const Divider(height: 24),
                  _DetailRow(
                    icon: Icons.confirmation_number_rounded,
                    label: 'Réservation',
                    value: '#${widget.bookingId.substring(0, 8)}',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Info
            if (!_isReleased)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.greenLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.green.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded,
                        size: 18, color: AppColors.green),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'En cliquant sur "Déposer", vous confirmez que le trajet s\'est bien déroulé et autorisez le transfert des fonds.',
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
            const SizedBox(height: 32),

            // Bouton
            if (!_isReleased)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isProcessing ? null : _releaseFunds,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isProcessing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Déposer les fonds'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Row(
      children: [
        Icon(icon, size: 20, color: cs.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: cs.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: valueColor ?? cs.onSurface,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
