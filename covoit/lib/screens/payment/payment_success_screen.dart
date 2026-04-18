import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../app_theme.dart';

class PaymentSuccessScreen extends StatefulWidget {
  final String amount;
  final String method;
  final bool isCaution;
  final String? reference;
  final String? detailMessage;
  final DateTime? paidAt;

  const PaymentSuccessScreen({
    super.key,
    required this.amount,
    required this.method,
    this.isCaution = false,
    this.reference,
    this.detailMessage,
    this.paidAt,
  });

  @override
  State<PaymentSuccessScreen> createState() => _PaymentSuccessScreenState();
}

class _PaymentSuccessScreenState extends State<PaymentSuccessScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _scaleAnim = Tween<double>(begin: 0.5, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut));
    _fadeAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final paidAt = widget.paidAt ?? DateTime.now();
    final formattedDate = DateFormat('dd/MM/yyyy · HH:mm').format(paidAt);
    final receiptReference = widget.reference ?? 'Paiement confirmé';
    final detailMessage = widget.detailMessage ??
        (widget.isCaution
            ? 'Votre caution est sécurisée. Elle vous sera remboursée si le chauffeur annule.'
            : 'Votre opération a été validée et votre réservation est désormais confirmée.');

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FadeTransition(
                opacity: _fadeAnim,
                child: ScaleTransition(
                  scale: _scaleAnim,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: const BoxDecoration(
                      color: AppColors.greenLight,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle_rounded,
                      color: AppColors.green,
                      size: 56,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Text(
                widget.isCaution ? 'Caution versée !' : 'Paiement réussi !',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '${widget.amount} FCFA via ${widget.method}',
                style: TextStyle(fontSize: 15, color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: 8),
              Text(
                detailMessage,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 13, color: cs.onSurfaceVariant, height: 1.5),
              ),
              const SizedBox(height: 36),

              // Récapitulatif
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _ReceiptRow(label: 'Référence', value: receiptReference),
                      const Divider(height: 16),
                      _ReceiptRow(
                          label: 'Montant', value: '${widget.amount} FCFA'),
                      const Divider(height: 16),
                      _ReceiptRow(label: 'Opérateur', value: widget.method),
                      const Divider(height: 16),
                      _ReceiptRow(label: 'Date', value: formattedDate),
                      const Divider(height: 16),
                      const _ReceiptRow(
                        label: 'Statut',
                        value: 'Confirmé',
                        valueColor: AppColors.green,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () =>
                      Navigator.popUntil(context, (r) => r.isFirst),
                  child: const Text('Retour à l\'accueil'),
                ),
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.download_rounded, size: 16),
                label: const Text('Télécharger le reçu'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReceiptRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _ReceiptRow(
      {required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
        Text(value,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: valueColor ?? cs.onSurface)),
      ],
    );
  }
}
