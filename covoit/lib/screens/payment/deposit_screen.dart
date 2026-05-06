import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app_theme.dart';
import 'payment_simulation_screen.dart';

/// Écran de dépôt de fonds (Passager)
/// Permet au passager d'entrer un montant à déposer pour une réservation
class DepositScreen extends ConsumerStatefulWidget {
  final String bookingId;
  final double amount;
  final String tripTitle;

  const DepositScreen({
    super.key,
    required this.bookingId,
    required this.amount,
    required this.tripTitle,
  });

  @override
  ConsumerState<DepositScreen> createState() => _DepositScreenState();
}

class _DepositScreenState extends ConsumerState<DepositScreen> {
  final _amountCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String _selectedMethod = 'mtn';

  @override
  void initState() {
    super.initState();
    _amountCtrl.text = widget.amount.toStringAsFixed(0);
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  void _proceedToPayment() {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.parse(_amountCtrl.text);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentSimulationScreen(
          bookingId: widget.bookingId,
          amount: amount,
          paymentMethod: _selectedMethod,
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
        title: const Text('Dépôt de fonds'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info trajet
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.route_rounded, size: 20, color: cs.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.tripTitle,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Réservation #${widget.bookingId.substring(0, 8)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Montant
              Text(
                'Montant à déposer',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _amountCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  hintText: '5000',
                  prefixIcon: Icon(Icons.payments_rounded, size: 20),
                  suffixText: 'FCFA',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Entrez un montant';
                  }
                  final amount = double.tryParse(value);
                  if (amount == null || amount <= 0) {
                    return 'Montant invalide';
                  }
                  if (amount < 500) {
                    return 'Montant minimum : 500 FCFA';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Méthode de paiement
              Text(
                'Méthode de paiement',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 12),

              _PaymentMethodTile(
                icon: Icons.phone_android_rounded,
                title: 'MTN Mobile Money',
                subtitle: 'Paiement via MTN MoMo',
                color: const Color(0xFFFFCC00),
                isSelected: _selectedMethod == 'mtn',
                onTap: () => setState(() => _selectedMethod = 'mtn'),
              ),
              const SizedBox(height: 12),

              _PaymentMethodTile(
                icon: Icons.phone_iphone_rounded,
                title: 'Orange Money',
                subtitle: 'Paiement via Orange Money',
                color: const Color(0xFFFF6600),
                isSelected: _selectedMethod == 'orange',
                onTap: () => setState(() => _selectedMethod = 'orange'),
              ),
              const SizedBox(height: 24),

              // Info séquestre
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.greenLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.green.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.lock_rounded, size: 18, color: AppColors.green),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Vos fonds seront bloqués en séquestre jusqu\'à la fin du trajet. Le chauffeur ne les recevra qu\'après validation.',
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

              // Bouton payer
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _proceedToPayment,
                  child: const Text('Continuer vers le paiement'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PaymentMethodTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _PaymentMethodTile({
    required this.icon,
    required this.title,
    required this.subtitle,
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
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
