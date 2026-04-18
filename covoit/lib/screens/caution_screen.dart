import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../app_theme.dart';
import '../data/providers/caution_providers.dart';
import '../data/providers/journey_providers.dart';

class CautionScreen extends ConsumerStatefulWidget {
  const CautionScreen({super.key});

  @override
  ConsumerState<CautionScreen> createState() => _CautionScreenState();
}

class _CautionScreenState extends ConsumerState<CautionScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final userIdAsync = ref.watch(currentUserIdProvider);

    return userIdAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Erreur: $e'))),
      data: (userId) {
        if (userId == null) {
          return const Scaffold(body: Center(child: Text('Connectez-vous')));
        }
        final cautionsAsync = ref.watch(userCautionsProvider(userId));
        final summaryAsync = ref.watch(cautionSummaryProvider(userId));

        return Scaffold(
          appBar: AppBar(
            title: const Text('Cautions & Remboursements'),
            bottom: TabBar(
              controller: _tabCtrl,
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white60,
              labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              tabs: const [
                Tab(text: 'En cours'),
                Tab(text: 'Remboursées'),
                Tab(text: 'Retenues'),
              ],
            ),
          ),
          body: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                color: AppColors.greenLight,
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_rounded, color: AppColors.green, size: 18),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'La caution de 500 FCFA par place/réservation est un gage de sécurité. Elle est remboursée automatiquement sous 24h si le trajet est annulé par le chauffeur.',
                        style: TextStyle(fontSize: 12, color: AppColors.greenDark, height: 1.5),
                      ),
                    ),
                  ],
                ),
              ),
              summaryAsync.when(
                loading: () => const SizedBox(height: 80, child: Center(child: CircularProgressIndicator())),
                error: (_, __) => _buildBalanceSummary(cs, 0, 0, 0),
                data: (summary) => _buildBalanceSummary(
                  cs,
                  summary['pending'] as int? ?? 0,
                  summary['refunded'] as int? ?? 0,
                  summary['retained'] as int? ?? 0,
                ),
              ),
              const Divider(height: 0),
              Expanded(
                child: cautionsAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Erreur: $e')),
                  data: (response) {
                    final all = (response['data'] as List?) ?? [];
                    final pending = all.where((c) => c['status'] == 'pending').toList();
                    final refunded = all.where((c) => c['status'] == 'refunded').toList();
                    final retained = all.where((c) => c['status'] == 'retained').toList();
                    return TabBarView(
                      controller: _tabCtrl,
                      children: [
                        _CautionList(items: pending),
                        _CautionList(items: refunded),
                        _CautionList(items: retained),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBalanceSummary(ColorScheme cs, int pending, int refunded, int retained) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: cs.surface,
      child: Row(
        children: [
          Expanded(
            child: _BalanceCard(
              label: 'En attente',
              amount: _formatAmount(pending),
              color: AppColors.prime,
              icon: Icons.hourglass_bottom_rounded,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _BalanceCard(
              label: 'Remboursées',
              amount: _formatAmount(refunded),
              color: AppColors.green,
              icon: Icons.check_circle_rounded,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _BalanceCard(
              label: 'Retenues',
              amount: _formatAmount(retained),
              color: AppColors.coral,
              icon: Icons.cancel_rounded,
            ),
          ),
        ],
      ),
    );
  }

  String _formatAmount(int amount) {
    if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(amount % 1000 == 0 ? 0 : 1)}k';
    }
    return '$amount';
  }
}

class _BalanceCard extends StatelessWidget {
  final String label;
  final String amount;
  final Color color;
  final IconData icon;

  const _BalanceCard({
    required this.label,
    required this.amount,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(height: 6),
          Text('$amount F',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: color)),
          Text(label,
              style: TextStyle(
                  fontSize: 10, color: cs.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _CautionList extends StatelessWidget {
  final List<dynamic> items;

  const _CautionList({required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shield_rounded, size: 52, color: AppColors.gray100),
            SizedBox(height: 14),
            Text('Aucune caution',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.gray400)),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) => _CautionCard(item: items[i]),
    );
  }
}

class _CautionCard extends StatelessWidget {
  final Map<String, dynamic> item;

  const _CautionCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final status = item['status'] as String? ?? 'pending';
    final tripRoute = item['trip_route'] as String? ?? 'Trajet inconnu';
    final amount = item['amount'] as int? ?? 0;
    final type = item['caution_type'] as String? ?? 'passenger';
    final reason = item['reason'] as String? ?? '';
    final createdAt = item['created_at'] as String? ?? '';

    String date = '';
    if (createdAt.isNotEmpty) {
      try {
        final dt = DateTime.parse(createdAt);
        date = '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
      } catch (_) {
        date = createdAt;
      }
    }

    Color statusColor;
    String statusLabel;
    IconData statusIcon;

    switch (status) {
      case 'refunded':
        statusColor = AppColors.green;
        statusLabel = 'Remboursée';
        statusIcon = Icons.check_circle_rounded;
        break;
      case 'retained':
        statusColor = AppColors.coral;
        statusLabel = 'Retenue';
        statusIcon = Icons.cancel_rounded;
        break;
      default:
        statusColor = AppColors.prime;
        statusLabel = 'En attente';
        statusIcon = Icons.hourglass_bottom_rounded;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(statusIcon, color: statusColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(tripRoute,
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: cs.onSurface)),
                      Text(date,
                          style: TextStyle(
                              fontSize: 12, color: cs.onSurfaceVariant)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('$amount F',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: statusColor)),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(statusLabel,
                          style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: statusColor)),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    type == 'passenger'
                        ? Icons.person_rounded
                        : Icons.drive_eta_rounded,
                    size: 14,
                    color: cs.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(reason,
                        style: TextStyle(
                            fontSize: 11,
                            color: cs.onSurfaceVariant,
                            height: 1.4)),
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
