import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app_theme.dart';

/// Écran d'état du séquestre (Passager)
/// Affiche que les fonds sont bloqués en attente de validation
class EscrowStatusScreen extends ConsumerWidget {
  final String bookingId;
  final double amount;
  final String tripTitle;

  const EscrowStatusScreen({
    super.key,
    required this.bookingId,
    required this.amount,
    required this.tripTitle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fonds en séquestre'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 20),

            // Icône de séquestre
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primeBg,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock_clock_rounded,
                size: 60,
                color: AppColors.prime,
              ),
            ),
            const SizedBox(height: 24),

            // Titre
            Text(
              'Fonds bloqués en séquestre',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Vos fonds sont sécurisés et seront libérés après validation du trajet',
              style: TextStyle(
                fontSize: 14,
                color: cs.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Montant bloqué
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Text(
                    'Montant bloqué',
                    style: TextStyle(
                      fontSize: 14,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${amount.toStringAsFixed(0)} FCFA',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: cs.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Détails
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: cs.outline.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  _DetailRow(
                    icon: Icons.route_rounded,
                    label: 'Trajet',
                    value: tripTitle,
                  ),
                  const Divider(height: 24),
                  _DetailRow(
                    icon: Icons.confirmation_number_rounded,
                    label: 'Réservation',
                    value: '#${bookingId.substring(0, 8)}',
                  ),
                  const Divider(height: 24),
                  _DetailRow(
                    icon: Icons.schedule_rounded,
                    label: 'Statut',
                    value: 'En attente de validation',
                    valueColor: AppColors.prime,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Étapes du processus
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.greenLight,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.green.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.info_outline_rounded,
                          size: 20, color: AppColors.green),
                      const SizedBox(width: 8),
                      Text(
                        'Prochaines étapes',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _ProcessStep(
                    number: 1,
                    title: 'Trajet en cours',
                    subtitle: 'Le chauffeur effectue le trajet',
                    isDone: true,
                  ),
                  const SizedBox(height: 12),
                  _ProcessStep(
                    number: 2,
                    title: 'Validation du trajet',
                    subtitle: 'Confirmation de la fin du trajet',
                    isDone: false,
                    isCurrent: true,
                  ),
                  const SizedBox(height: 12),
                  _ProcessStep(
                    number: 3,
                    title: 'Libération des fonds',
                    subtitle: 'Le chauffeur reçoit le paiement',
                    isDone: false,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Bouton retour
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Retour à l'écran précédent (mes trajets)
                  Navigator.popUntil(context, (route) => route.isFirst);
                },
                child: const Text('Retour à mes trajets'),
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

class _ProcessStep extends StatelessWidget {
  final int number;
  final String title;
  final String subtitle;
  final bool isDone;
  final bool isCurrent;

  const _ProcessStep({
    required this.number,
    required this.title,
    required this.subtitle,
    this.isDone = false,
    this.isCurrent = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isDone
                ? AppColors.green
                : isCurrent
                    ? AppColors.prime
                    : cs.surfaceContainerHighest,
            shape: BoxShape.circle,
            border: Border.all(
              color: isDone
                  ? AppColors.green
                  : isCurrent
                      ? AppColors.prime
                      : cs.outline,
              width: 2,
            ),
          ),
          child: Center(
            child: isDone
                ? const Icon(Icons.check, size: 16, color: Colors.white)
                : Text(
                    '$number',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isCurrent ? Colors.white : cs.onSurfaceVariant,
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
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
