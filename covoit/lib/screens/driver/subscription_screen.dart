import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app_theme.dart';
import '../../data/providers/journey_providers.dart';
import '../../data/providers/subscription_providers.dart';
import '../payment/payment_screen.dart';

class SubscriptionScreen extends ConsumerStatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  ConsumerState<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends ConsumerState<SubscriptionScreen> {
  String _plan = 'monthly';
  bool _cancelling = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final plansAsync = ref.watch(subscriptionPlansProvider);
    final userIdAsync = ref.watch(currentUserIdProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Abonnement Prime')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Active subscription banner
            userIdAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (userId) {
                if (userId == null || userId.isEmpty) return const SizedBox.shrink();
                return ref.watch(userSubscriptionProvider(userId)).when(
                  loading: () => const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (response) {
                    final sub = response['data'] as Map<String, dynamic>?;
                    if (sub == null || sub['status'] != 'active') return const SizedBox.shrink();
                    final expiresAt = sub['expires_at'] as String?;
                    final planType = sub['plan_type'] as String? ?? '';
                    final planLabel = planType == 'monthly' ? 'Mensuel'
                        : planType == 'quarterly' ? 'Trimestriel' : 'Annuel';
                    String expiryText = '';
                    if (expiresAt != null) {
                      final dt = DateTime.tryParse(expiresAt);
                      if (dt != null) {
                        final diff = dt.difference(DateTime.now()).inDays;
                        expiryText = 'Expire dans $diff jour${diff > 1 ? 's' : ''}';
                      }
                    }
                    return _ActiveSubscriptionBanner(
                      planLabel: planLabel,
                      expiryText: expiryText,
                      cancelling: _cancelling,
                      onCancel: () => _cancelSubscription(userId),
                    );
                  },
                );
              },
            ),
            // Hero
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFBA7517), AppColors.prime],
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.workspace_premium_rounded,
                        color: Colors.white, size: 40),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Devenez Chauffeur Prime',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Visibilité maximale, plus de revenus,\ncommunauté exclusive.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.white70, fontSize: 14, height: 1.5),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avantages
                  Text('Avantages Prime',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: cs.onSurface)),
                  const SizedBox(height: 12),
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _BenefitTile(
                            icon: Icons.visibility_rounded,
                            title: 'Visibilité maximale',
                            subtitle:
                                'Apparaissez en tête des résultats de recherche',
                            color: AppColors.green,
                          ),
                          Divider(height: 20),
                          _BenefitTile(
                            icon: Icons.forum_rounded,
                            title: 'Forum exclusif Prime',
                            subtitle:
                                'Communauté privée de chauffeurs vérifiés',
                            color: AppColors.prime,
                          ),
                          Divider(height: 20),
                          _BenefitTile(
                            icon: Icons.workspace_premium_rounded,
                            title: 'Badge Prime visible',
                            subtitle:
                                'Inspirez confiance avec le badge doré sur votre profil',
                            color: AppColors.prime,
                          ),
                          Divider(height: 20),
                          _BenefitTile(
                            icon: Icons.trending_up_rounded,
                            title: 'Plus de réservations',
                            subtitle:
                                'Les passagers préfèrent les chauffeurs Prime',
                            color: AppColors.green,
                          ),
                          Divider(height: 20),
                          _BenefitTile(
                            icon: Icons.support_agent_rounded,
                            title: 'Support prioritaire',
                            subtitle: 'Assistance dédiée 24h/7j',
                            color: AppColors.green,
                          ),
                          Divider(height: 20),
                          _BenefitTile(
                            icon: Icons.money_off_rounded,
                            title: 'Caution réduite',
                            subtitle:
                                'Taux de caution préférentiel par rapport aux simples',
                            color: AppColors.prime,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Plans
                  Text('Choisissez votre formule',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: cs.onSurface)),
                  const SizedBox(height: 12),

                  plansAsync.when(
                    loading: () => const Center(child: Padding(
                      padding: EdgeInsets.all(20),
                      child: CircularProgressIndicator(),
                    )),
                    error: (_, __) => _buildStaticPlans(),
                    data: (response) {
                      final plans = (response['data'] as List?) ?? [];
                      if (plans.isEmpty) return _buildStaticPlans();
                      return Column(
                        children: plans.map<Widget>((p) {
                          final planType = p['plan_type'] as String? ?? 'monthly';
                          final name = p['name'] as String? ?? planType;
                          final price = p['price'] as int? ?? 0;
                          final savings = p['savings'] as String?;
                          final isHighlighted = p['is_highlighted'] as bool? ?? false;
                          final period = planType == 'monthly'
                              ? 'par mois'
                              : planType == 'quarterly'
                                  ? '/ 3 mois'
                                  : 'par an';

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _PlanCard(
                              value: planType,
                              selected: _plan == planType,
                              onTap: () => setState(() => _plan = planType),
                              title: name,
                              price: _formatPrice(price),
                              period: period,
                              savings: savings,
                              highlighted: isHighlighted,
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),

                  const SizedBox(height: 18),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        // Lire le prix depuis l'API si disponible, sinon fallback statique
                        final plans = (plansAsync.valueOrNull ?? {})['data'] as List? ?? [];
                        final selectedPlan = plans.cast<Map<String, dynamic>>()
                            .where((p) => p['plan_type'] == _plan)
                            .firstOrNull;
                        final price = selectedPlan?['price'] as int?
                            ?? (_plan == 'monthly' ? 5000 : _plan == 'quarterly' ? 12000 : 40000);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PaymentScreen(
                              amount: price.toString(),
                              description:
                                  'Abonnement Prime ${_plan == 'monthly' ? 'mensuel' : _plan == 'quarterly' ? 'trimestriel' : 'annuel'}',
                              paymentType: 'subscription',
                              planType: _plan,
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.prime,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text(
                        'Activer Prime maintenant',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: Text(
                      'Annulation possible à tout moment',
                      style:
                          TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatPrice(int price) {
    if (price >= 1000) {
      final str = price.toString();
      final buffer = StringBuffer();
      for (int i = 0; i < str.length; i++) {
        if (i > 0 && (str.length - i) % 3 == 0) buffer.write(' ');
        buffer.write(str[i]);
      }
      return buffer.toString();
    }
    return price.toString();
  }

  Widget _buildStaticPlans() {
    return Column(
      children: [
        _PlanCard(
          value: 'monthly', selected: _plan == 'monthly',
          onTap: () => setState(() => _plan = 'monthly'),
          title: 'Mensuel', price: '5 000', period: 'par mois', savings: null,
        ),
        const SizedBox(height: 10),
        _PlanCard(
          value: 'quarterly', selected: _plan == 'quarterly',
          onTap: () => setState(() => _plan = 'quarterly'),
          title: 'Trimestriel', price: '12 000', period: '/ 3 mois',
          savings: 'Économisez 3 000 FCFA',
        ),
        const SizedBox(height: 10),
        _PlanCard(
          value: 'yearly', selected: _plan == 'yearly',
          onTap: () => setState(() => _plan = 'yearly'),
          title: 'Annuel', price: '40 000', period: 'par an',
          savings: 'Économisez 20 000 FCFA', highlighted: true,
        ),
      ],
    );
  }

  Future<void> _cancelSubscription(String userId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Annuler l\'abonnement'),
        content: const Text(
          'Êtes-vous sûr de vouloir annuler votre abonnement Prime ? '
          'Vous perdrez tous les avantages à la fin de la période en cours.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Non')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Oui, annuler', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    setState(() => _cancelling = true);
    try {
      final repo = ref.read(subscriptionRepositoryProvider);
      await repo.cancel(userId);
      ref.invalidate(userSubscriptionProvider(userId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Abonnement annulé avec succès.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _cancelling = false);
    }
  }
}

class _ActiveSubscriptionBanner extends StatelessWidget {
  final String planLabel;
  final String expiryText;
  final bool cancelling;
  final VoidCallback onCancel;

  const _ActiveSubscriptionBanner({
    required this.planLabel,
    required this.expiryText,
    required this.cancelling,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFBA7517), AppColors.prime],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 36),
          const SizedBox(height: 8),
          const Text(
            'Abonnement Prime Actif',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            'Formule $planLabel',
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          if (expiryText.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              expiryText,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ],
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: cancelling ? null : onCancel,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white54),
              ),
              child: cancelling
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Annuler l\'abonnement'),
            ),
          ),
        ],
      ),
    );
  }
}

class _BenefitTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const _BenefitTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface)),
              const SizedBox(height: 2),
              Text(subtitle,
                  style: TextStyle(
                      fontSize: 12, color: cs.onSurfaceVariant, height: 1.4)),
            ],
          ),
        ),
        Icon(Icons.check_circle_rounded, color: color, size: 18),
      ],
    );
  }
}

class _PlanCard extends StatelessWidget {
  final String value;
  final bool selected;
  final VoidCallback onTap;
  final String title;
  final String price;
  final String period;
  final String? savings;
  final bool highlighted;

  const _PlanCard({
    required this.value,
    required this.selected,
    required this.onTap,
    required this.title,
    required this.price,
    required this.period,
    this.savings,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color:
              selected ? AppColors.prime.withValues(alpha: 0.08) : cs.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color:
                selected ? AppColors.prime : cs.outline.withValues(alpha: 0.5),
            width: selected ? 2 : 0.5,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: selected ? AppColors.prime : cs.outline,
              size: 22,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(title,
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: cs.onSurface)),
                      if (highlighted) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.green,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text('MEILLEURE OFFRE',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800)),
                        ),
                      ],
                    ],
                  ),
                  if (savings != null)
                    Text(savings!,
                        style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.green,
                            fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('$price F',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: selected ? AppColors.prime : cs.onSurface)),
                Text(period,
                    style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
