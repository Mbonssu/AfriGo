import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';

import '../../app_theme.dart';
import '../../data/providers/payment_simulation_provider.dart';

/// Écran d'abonnement Prime avec simulation de paiement
class PrimeSubscriptionScreen extends ConsumerStatefulWidget {
  const PrimeSubscriptionScreen({super.key});

  @override
  ConsumerState<PrimeSubscriptionScreen> createState() =>
      _PrimeSubscriptionScreenState();
}

class _PrimeSubscriptionScreenState
    extends ConsumerState<PrimeSubscriptionScreen> {
  String _selectedPlan = 'monthly';
  String _selectedMethod = 'mtn';
  bool _isProcessing = false;

  final Map<String, Map<String, dynamic>> _plans = {
    'monthly': {
      'name': 'Mensuel',
      'price': 5000.0,
      'duration': '1 mois',
      'savings': null,
    },
    'quarterly': {
      'name': 'Trimestriel',
      'price': 12000.0,
      'duration': '3 mois',
      'savings': '20%',
    },
    'yearly': {
      'name': 'Annuel',
      'price': 40000.0,
      'duration': '12 mois',
      'savings': '33%',
    },
  };

  Future<void> _subscribe() async {
    setState(() => _isProcessing = true);

    // Simulation : attendre 3 secondes
    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;

    // Activer le statut Prime dans le provider
    ref.read(paymentSimulationProvider.notifier).activatePrime();

    setState(() => _isProcessing = false);

    // Afficher le dialogue de succès
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
                color: AppColors.primeBg,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.star_rounded,
                size: 60,
                color: AppColors.prime,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Bienvenue dans Prime !',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Votre abonnement ${_plans[_selectedPlan]!['name']} est maintenant actif.',
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.greenLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.check_circle_rounded,
                          size: 16, color: AppColors.green),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Accès au forum Prime',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.check_circle_rounded,
                          size: 16, color: AppColors.green),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Badge vérifié',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.check_circle_rounded,
                          size: 16, color: AppColors.green),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Priorité dans les recherches',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
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
                      'Mode simulation : Aucun paiement réel',
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
              Navigator.pop(context); // Retour à l'écran précédent
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.prime,
            ),
            child: const Text('Découvrir Prime'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final selectedPlan = _plans[_selectedPlan]!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Abonnement Prime'),
        backgroundColor: AppColors.prime,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Prime
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.prime, AppColors.primeDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                children: [
                  const Icon(Icons.star_rounded, size: 60, color: Colors.white),
                  const SizedBox(height: 16),
                  const Text(
                    'AfriGo PRIME',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Rejoignez l\'élite du covoiturage',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avantages
                  Text(
                    'Avantages Prime',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _BenefitTile(
                    icon: Icons.verified_rounded,
                    title: 'Badge vérifié',
                    subtitle: 'Profil certifié et prioritaire',
                  ),
                  const SizedBox(height: 12),
                  _BenefitTile(
                    icon: Icons.forum_rounded,
                    title: 'Forum exclusif',
                    subtitle: 'Accès au forum Prime',
                  ),
                  const SizedBox(height: 12),
                  _BenefitTile(
                    icon: Icons.trending_up_rounded,
                    title: 'Visibilité accrue',
                    subtitle: 'Apparaissez en premier',
                  ),
                  const SizedBox(height: 12),
                  _BenefitTile(
                    icon: Icons.support_agent_rounded,
                    title: 'Support prioritaire',
                    subtitle: 'Assistance dédiée 24/7',
                  ),
                  const SizedBox(height: 24),

                  // Plans
                  Text(
                    'Choisissez votre plan',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 16),

                  ..._plans.entries.map((entry) {
                    final plan = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _PlanTile(
                        name: plan['name'],
                        price: plan['price'],
                        duration: plan['duration'],
                        savings: plan['savings'],
                        isSelected: _selectedPlan == entry.key,
                        onTap: () => setState(() => _selectedPlan = entry.key),
                      ),
                    );
                  }).toList(),

                  const SizedBox(height: 24),

                  // Méthode de paiement
                  Text(
                    'Méthode de paiement',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 16),

                  _PaymentMethodTile(
                    icon: Icons.phone_android_rounded,
                    title: 'MTN Mobile Money',
                    color: const Color(0xFFFFCC00),
                    isSelected: _selectedMethod == 'mtn',
                    onTap: () => setState(() => _selectedMethod = 'mtn'),
                  ),
                  const SizedBox(height: 12),

                  _PaymentMethodTile(
                    icon: Icons.phone_iphone_rounded,
                    title: 'Orange Money',
                    color: const Color(0xFFFF6600),
                    isSelected: _selectedMethod == 'orange',
                    onTap: () => setState(() => _selectedMethod = 'orange'),
                  ),
                  const SizedBox(height: 32),

                  // Bouton s'abonner
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isProcessing ? null : _subscribe,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.prime,
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
                          : Text(
                              'S\'abonner - ${selectedPlan['price'].toStringAsFixed(0)} FCFA',
                              style: const TextStyle(fontSize: 16),
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
}

class _BenefitTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _BenefitTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primeBg,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.prime, size: 24),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PlanTile extends StatelessWidget {
  final String name;
  final double price;
  final String duration;
  final String? savings;
  final bool isSelected;
  final VoidCallback onTap;

  const _PlanTile({
    required this.name,
    required this.price,
    required this.duration,
    this.savings,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primeBg : cs.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.prime : cs.outline.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: cs.onSurface,
                        ),
                      ),
                      if (savings != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.green,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Économisez $savings',
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    duration,
                    style: TextStyle(
                      fontSize: 12,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '${price.toStringAsFixed(0)} F',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: isSelected ? AppColors.prime : cs.onSurface,
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              isSelected ? Icons.check_circle_rounded : Icons.circle_outlined,
              color: isSelected ? AppColors.prime : cs.outline,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentMethodTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _PaymentMethodTile({
    required this.icon,
    required this.title,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? cs.primaryContainer : cs.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? cs.primary : cs.outline.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface,
                ),
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle_rounded, color: cs.primary, size: 24)
            else
              Icon(Icons.circle_outlined, color: cs.outline, size: 24),
          ],
        ),
      ),
    );
  }
}
