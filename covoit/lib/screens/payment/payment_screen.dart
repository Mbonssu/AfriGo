import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app_theme.dart';
import '../../core/errors/exceptions.dart';
import '../../data/models/app_payment.dart';
import '../../data/providers/journey_providers.dart';
import '../../data/providers/payment_providers.dart';
import '../../data/providers/subscription_providers.dart';
import 'payment_success_screen.dart';

class PaymentScreen extends ConsumerStatefulWidget {
  final String amount;
  final String description;
  final bool isCaution;
  final String paymentType;
  final String initialMethod;
  final String? tripId;
  final int? seatCount;
  final String? bookingId;
  final String? planType;

  const PaymentScreen({
    super.key,
    required this.amount,
    required this.description,
    required this.paymentType,
    this.isCaution = false,
    this.initialMethod = 'mtn',
    this.tripId,
    this.seatCount,
    this.bookingId,
    this.planType,
  });

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  late String _method;
  final _phoneCtrl = TextEditingController(text: '+237 ');
  bool _loading = false;
  bool _awaitingConfirmation = false;
  String? _providerMessage;
  String? _channelUssd;
  String? _currentPaymentId;
  String? _currentBookingId;

  @override
  void initState() {
    super.initState();
    _method = widget.initialMethod;
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    super.dispose();
  }

  int get _amountValue {
    final digits = widget.amount.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(digits) ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Paiement')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.greenLight,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.green.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    widget.isCaution ? 'Caution à verser' : 'Montant à payer',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.greenDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${widget.amount} FCFA',
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                      color: AppColors.green,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.description,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.greenDark,
                    ),
                  ),
                  if (widget.isCaution) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.green.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Remboursable si le chauffeur annule',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.greenDark,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Choisissez votre opérateur',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            _MethodCard(
              selected: _method == 'mtn',
              onTap: _loading ? null : () => setState(() => _method = 'mtn'),
              logo: '🟡',
              name: 'MTN Mobile Money',
              description: 'Paiement via Monetbil',
              color: const Color(0xFFFFCC00),
            ),
            const SizedBox(height: 10),
            _MethodCard(
              selected: _method == 'orange',
              onTap: _loading ? null : () => setState(() => _method = 'orange'),
              logo: '🟠',
              name: 'Orange Money',
              description: 'Paiement via Monetbil',
              color: const Color(0xFFFF6600),
            ),
            const SizedBox(height: 24),
            Text(
              'Numéro ${_method == 'mtn' ? 'MTN' : 'Orange'}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              enabled: !_loading,
              decoration: InputDecoration(
                hintText: '+237 6XX XXX XXX',
                prefixIcon: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    _method == 'mtn' ? '🟡' : '🟠',
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        size: 16,
                        color: cs.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Comment ça marche',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _Step(
                    number: '1',
                    text:
                        'Entrez votre numéro ${_method == 'mtn' ? 'MTN' : 'Orange'}',
                  ),
                  const SizedBox(height: 6),
                  const _Step(
                    number: '2',
                    text: 'Appuyez sur "Payer maintenant"',
                  ),
                  const SizedBox(height: 6),
                  _Step(
                    number: '3',
                    text: _channelUssd != null && _channelUssd!.isNotEmpty
                        ? 'Confirmez ensuite via ${_channelUssd!}'
                        : 'Validez la demande Mobile Money sur votre téléphone',
                  ),
                  const SizedBox(height: 6),
                  _Step(
                    number: '4',
                    text: widget.paymentType == 'subscription'
                        ? 'Votre abonnement Prime sera activé automatiquement'
                        : 'Votre réservation sera confirmée automatiquement',
                  ),
                ],
              ),
            ),
            if (_providerMessage != null || _currentPaymentId != null) ...[
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.green.withValues(alpha: 0.15),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _awaitingConfirmation
                              ? Icons.hourglass_top_rounded
                              : Icons.receipt_long_rounded,
                          size: 18,
                          color: AppColors.green,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _awaitingConfirmation
                              ? 'Confirmation en cours'
                              : 'Suivi du paiement',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: cs.onSurface,
                          ),
                        ),
                      ],
                    ),
                    if (_providerMessage != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        _providerMessage!,
                        style: TextStyle(
                          fontSize: 12,
                          color: cs.onSurfaceVariant,
                          height: 1.45,
                        ),
                      ),
                    ],
                    if (_currentPaymentId != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Référence: $_currentPaymentId',
                        style: TextStyle(
                          fontSize: 11,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                    if (_awaitingConfirmation) ...[
                      const SizedBox(height: 12),
                      const LinearProgressIndicator(),
                    ],
                  ],
                ),
              ),
            ],
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading
                    ? null
                    : _currentPaymentId != null
                        ? () => _verifyCurrentPayment()
                        : _processPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _method == 'mtn'
                      ? const Color(0xFFFFCC00)
                      : const Color(0xFFFF6600),
                  foregroundColor:
                      _method == 'mtn' ? Colors.black87 : Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _loading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        _awaitingConfirmation
                            ? 'Vérification en cours...'
                            : _currentPaymentId != null
                                ? 'Vérifier le paiement'
                                : 'Payer ${widget.amount} FCFA',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
            if (_currentPaymentId != null && !_awaitingConfirmation) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _loading ? null : () => _verifyCurrentPayment(),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Vérifier maintenant'),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lock_rounded,
                      size: 14, color: cs.onSurfaceVariant),
                  const SizedBox(width: 5),
                  Text(
                    'Paiement sécurisé via Monetbil',
                    style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Future<void> _processPayment() async {
    final phoneNumber = _phoneCtrl.text.trim();
    if (!_isPhoneValid(phoneNumber)) {
      _showSnack('Entrez un numéro Mobile Money valide (+237 6XX XXX XXX).');
      return;
    }
    if (_amountValue <= 0) {
      _showSnack('Le montant du paiement est invalide.');
      return;
    }
    if (_amountValue > 1000000) {
      _showSnack('Le montant maximum par transaction est de 1 000 000 FCFA.');
      return;
    }

    setState(() => _loading = true);

    String? createdBookingId;
    try {
      final userId = await ref.read(currentUserIdProvider.future);
      if (userId == null || userId.isEmpty) {
        throw const UnauthorizedException();
      }

      if (widget.paymentType == 'booking') {
        final tripId = widget.tripId;
        final seatCount = widget.seatCount;
        if (tripId == null ||
            tripId.isEmpty ||
            seatCount == null ||
            seatCount < 1) {
          throw const ServerException(
              'Informations de réservation incomplètes.');
        }

        createdBookingId = widget.bookingId ??
            await ref.read(journeyRepositoryProvider).createBooking(
                  tripId: tripId,
                  passengerId: userId,
                  numberOfSeats: seatCount,
                  totalPrice: _amountValue,
                );
      }

      final payment = await ref.read(paymentRepositoryProvider).initiatePayment(
            userId: userId,
            bookingId: createdBookingId,
            amount: _amountValue,
            paymentMethod: _method,
            paymentType: widget.paymentType,
            phoneNumber: phoneNumber,
            description: widget.description,
          );

      if (!mounted) return;
      setState(() {
        _currentBookingId = createdBookingId;
        _currentPaymentId = payment.paymentId;
        _providerMessage = payment.message;
        _channelUssd = payment.channelUssd;
        _awaitingConfirmation = true;
      });

      await _pollPaymentStatus();
    } on AppException catch (error) {
      if (createdBookingId != null && _currentPaymentId == null) {
        await _cancelBookingSilently(createdBookingId, error.message);
      }
      _showSnack(error.message);
    } catch (error) {
      if (createdBookingId != null && _currentPaymentId == null) {
        await _cancelBookingSilently(createdBookingId, error.toString());
      }
      _showSnack(_friendlyError(error));
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _pollPaymentStatus() async {
    for (var attempt = 0; attempt < 18; attempt++) {
      await Future.delayed(Duration(seconds: attempt == 0 ? 3 : 4));
      final isFinal = await _verifyCurrentPayment(internalCall: true);
      if (isFinal) {
        return;
      }
    }

    if (!mounted) return;
    setState(() => _awaitingConfirmation = false);
    _showSnack(
      'La confirmation prend plus de temps que prévu. Vous pouvez relancer la vérification.',
    );
  }

  Future<bool> _verifyCurrentPayment({bool internalCall = false}) async {
    final paymentId = _currentPaymentId;
    if (paymentId == null || paymentId.isEmpty) {
      return false;
    }

    if (!internalCall && mounted) {
      setState(() => _loading = true);
    }

    try {
      final verification =
          await ref.read(paymentRepositoryProvider).verifyPayment(paymentId);
      return _handleVerification(verification);
    } on AppException catch (error) {
      if (!internalCall) {
        _showSnack(error.message);
      }
      return false;
    } catch (error) {
      if (!internalCall) {
        _showSnack(_friendlyError(error));
      }
      return false;
    } finally {
      if (!internalCall && mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<bool> _handleVerification(AppPaymentVerification verification) async {
    if (!mounted) return true;

    setState(() {
      _providerMessage = verification.message;
      _awaitingConfirmation = !verification.isFinal;
    });

    if (verification.isSuccess) {
      var successMessage = verification.message;
      if (_currentBookingId != null) {
        try {
          await ref.read(journeyRepositoryProvider).confirmBooking(
                bookingId: _currentBookingId!,
                paymentId: verification.paymentId,
              );
        } catch (_) {
          successMessage =
              'Paiement confirmé. La réservation sera synchronisée dans quelques instants.';
        }
      } else if (widget.paymentType == 'subscription') {
        try {
          final subRepo = ref.read(subscriptionRepositoryProvider);
          final subUserId = await ref.read(currentUserIdProvider.future);
          await subRepo.subscribe(
            userId: subUserId!,
            planType: widget.planType ?? 'monthly',
            paymentReference: verification.paymentId,
          );
          successMessage = 'Paiement confirmé. Votre abonnement Prime est actif !';
        } catch (_) {
          successMessage = 'Paiement confirmé. L\'abonnement sera activé sous peu.';
        }
      }

      if (!mounted) return true;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => PaymentSuccessScreen(
            amount: widget.amount,
            method: _method == 'mtn' ? 'MTN Mobile Money' : 'Orange Money',
            isCaution: widget.isCaution,
            reference: verification.providerPaymentId ?? verification.paymentId,
            detailMessage: successMessage,
            paidAt: DateTime.now(),
          ),
        ),
      );
      return true;
    }

    if (verification.isFinal) {
      if (_currentBookingId != null) {
        await _cancelBookingSilently(_currentBookingId!, verification.message);
      }
      if (mounted) {
        setState(() {
          _currentPaymentId = null;
          _currentBookingId = null;
          _channelUssd = null;
        });
      }
      _showSnack(
        verification.message.isNotEmpty
            ? verification.message
            : 'Le paiement n’a pas été confirmé.',
      );
      return true;
    }

    return false;
  }

  Future<void> _cancelBookingSilently(String bookingId, String reason) async {
    try {
      await ref.read(journeyRepositoryProvider).cancelBooking(bookingId);
    } catch (_) {
      if (mounted) {
        setState(() {
          _providerMessage ??= reason;
        });
      }
    }
  }

  bool _isPhoneValid(String value) {
    final cleaned = value.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    final intl = RegExp(r'^\+?237[6-9]\d{8}$');
    final local = RegExp(r'^[6-9]\d{8}$');
    return intl.hasMatch(cleaned) || local.hasMatch(cleaned);
  }

  String _friendlyError(Object error) {
    final message = error.toString();
    if (message.contains('MONETBIL_SERVICE_KEY')) {
      return 'La clé Monetbil n’est pas encore configurée côté backend.';
    }
    return message.replaceFirst('Exception: ', '');
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

class _MethodCard extends StatelessWidget {
  final bool selected;
  final VoidCallback? onTap;
  final String logo;
  final String name;
  final String description;
  final Color color;

  const _MethodCard({
    required this.selected,
    required this.onTap,
    required this.logo,
    required this.name,
    required this.description,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.08) : cs.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? color : cs.outline.withValues(alpha: 0.5),
            width: selected ? 2 : 0.5,
          ),
        ),
        child: Row(
          children: [
            Text(logo, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                    ),
                  ),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              Icon(Icons.check_circle_rounded, color: color, size: 22)
            else
              Icon(
                Icons.radio_button_unchecked_rounded,
                color: cs.outline,
                size: 22,
              ),
          ],
        ),
      ),
    );
  }
}

class _Step extends StatelessWidget {
  final String number;
  final String text;

  const _Step({required this.number, required this.text});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 18,
          height: 18,
          decoration: const BoxDecoration(
            color: AppColors.green,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            number,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: cs.onSurfaceVariant,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}
