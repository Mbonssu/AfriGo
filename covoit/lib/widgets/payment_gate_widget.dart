import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app_theme.dart';
import '../data/providers/payment_simulation_provider.dart';
import '../screens/payment/prime_subscription_screen.dart';
import '../screens/payment/deposit_screen.dart';

/// Widget de garde pour les fonctionnalités payantes
/// Affiche un écran de verrouillage si la fonctionnalité n'est pas débloquée
class PaymentGate extends ConsumerWidget {
  final String featureName;
  final String title;
  final String description;
  final IconData icon;
  final Widget child;
  final bool requiresPrime;
  final bool requiresPayment;
  final VoidCallback? onUnlock;

  const PaymentGate({
    super.key,
    required this.featureName,
    required this.title,
    required this.description,
    required this.icon,
    required this.child,
    this.requiresPrime = false,
    this.requiresPayment = false,
    this.onUnlock,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPrimeActive = ref.watch(isPrimeActiveProvider);
    final hasCompletedPayment = ref.watch(hasCompletedPaymentProvider);
    final isFeatureUnlocked = ref.watch(isFeatureUnlockedProvider(featureName));

    // Vérifier si la fonctionnalité est débloquée
    final isUnlocked = isFeatureUnlocked ||
        (requiresPrime && isPrimeActive) ||
        (requiresPayment && hasCompletedPayment);

    if (isUnlocked) {
      return child;
    }

    // Afficher l'écran de verrouillage
    return _LockedFeatureScreen(
      title: title,
      description: description,
      icon: icon,
      requiresPrime: requiresPrime,
      requiresPayment: requiresPayment,
      onUnlock: () {
        if (requiresPrime) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const PrimeSubscriptionScreen(),
            ),
          );
        } else if (onUnlock != null) {
          onUnlock!();
        } else {
          // Débloquer directement en mode simulation
          ref.read(paymentSimulationProvider.notifier).unlockFeature(featureName);
        }
      },
    );
  }
}

class _LockedFeatureScreen extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final bool requiresPrime;
  final bool requiresPayment;
  final VoidCallback onUnlock;

  const _LockedFeatureScreen({
    required this.title,
    required this.description,
    required this.icon,
    required this.requiresPrime,
    required this.requiresPayment,
    required this.onUnlock,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icône verrouillée
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: requiresPrime
                      ? AppColors.primeBg
                      : cs.surfaceContainerHighest,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.lock_rounded,
                  size: 60,
                  color: requiresPrime ? AppColors.prime : cs.primary,
                ),
              ),
              const SizedBox(height: 24),

              // Titre
              Text(
                requiresPrime ? 'Fonctionnalité Prime' : 'Fonctionnalité verrouillée',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              // Description
              Text(
                description,
                style: TextStyle(
                  fontSize: 14,
                  color: cs.onSurfaceVariant,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Avantages
              if (requiresPrime) ...[
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.primeBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.prime.withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.star_rounded,
                              size: 20, color: AppColors.prime),
                          const SizedBox(width: 8),
                          Text(
                            'Avec Prime, vous débloquez :',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: cs.onSurface,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _BenefitRow(icon: icon, text: title),
                      const SizedBox(height: 8),
                      const _BenefitRow(
                        icon: Icons.verified_rounded,
                        text: 'Badge vérifié',
                      ),
                      const SizedBox(height: 8),
                      const _BenefitRow(
                        icon: Icons.trending_up_rounded,
                        text: 'Visibilité accrue',
                      ),
                      const SizedBox(height: 8),
                      const _BenefitRow(
                        icon: Icons.support_agent_rounded,
                        text: 'Support prioritaire',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Bouton débloquer
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onUnlock,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: requiresPrime ? AppColors.prime : cs.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  icon: Icon(
                    requiresPrime ? Icons.star_rounded : Icons.lock_open_rounded,
                  ),
                  label: Text(
                    requiresPrime
                        ? 'Passer à Prime'
                        : requiresPayment
                            ? 'Effectuer le paiement'
                            : 'Débloquer (Simulation)',
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Info simulation
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.info_outline_rounded,
                        size: 16, color: cs.primary),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Mode simulation : Cliquez pour débloquer gratuitement',
                        style: TextStyle(
                          fontSize: 11,
                          color: cs.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BenefitRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _BenefitRow({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.prime),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 12),
          ),
        ),
      ],
    );
  }
}
