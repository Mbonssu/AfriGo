import 'package:flutter_riverpod/flutter_riverpod.dart';

/// État de simulation des paiements
/// Permet de débloquer toutes les fonctionnalités payantes en mode simulation
class PaymentSimulationState {
  final bool isPrimeActive;
  final bool hasCompletedPayment;
  final Map<String, bool> unlockedFeatures;

  const PaymentSimulationState({
    this.isPrimeActive = false,
    this.hasCompletedPayment = false,
    this.unlockedFeatures = const {},
  });

  PaymentSimulationState copyWith({
    bool? isPrimeActive,
    bool? hasCompletedPayment,
    Map<String, bool>? unlockedFeatures,
  }) {
    return PaymentSimulationState(
      isPrimeActive: isPrimeActive ?? this.isPrimeActive,
      hasCompletedPayment: hasCompletedPayment ?? this.hasCompletedPayment,
      unlockedFeatures: unlockedFeatures ?? this.unlockedFeatures,
    );
  }
}

/// Notifier pour gérer l'état de simulation des paiements
class PaymentSimulationNotifier extends StateNotifier<PaymentSimulationState> {
  PaymentSimulationNotifier() : super(const PaymentSimulationState());

  /// Active l'abonnement Prime (simulation)
  void activatePrime() {
    state = state.copyWith(
      isPrimeActive: true,
      unlockedFeatures: {
        ...state.unlockedFeatures,
        'prime_forum': true,
        'prime_badge': true,
        'priority_listing': true,
        'advanced_stats': true,
      },
    );
  }

  /// Désactive l'abonnement Prime
  void deactivatePrime() {
    state = state.copyWith(
      isPrimeActive: false,
      unlockedFeatures: {
        ...state.unlockedFeatures,
        'prime_forum': false,
        'prime_badge': false,
        'priority_listing': false,
        'advanced_stats': false,
      },
    );
  }

  /// Marque un paiement comme complété (simulation)
  void completePayment(String bookingId) {
    state = state.copyWith(
      hasCompletedPayment: true,
      unlockedFeatures: {
        ...state.unlockedFeatures,
        'booking_$bookingId': true,
      },
    );
  }

  /// Débloque une fonctionnalité spécifique
  void unlockFeature(String featureName) {
    state = state.copyWith(
      unlockedFeatures: {
        ...state.unlockedFeatures,
        featureName: true,
      },
    );
  }

  /// Vérifie si une fonctionnalité est débloquée
  bool isFeatureUnlocked(String featureName) {
    return state.unlockedFeatures[featureName] ?? false;
  }

  /// Réinitialise tous les paiements (pour les tests)
  void reset() {
    state = const PaymentSimulationState();
  }

  /// Active le mode "tout débloqué" pour la démo
  void unlockAll() {
    state = state.copyWith(
      isPrimeActive: true,
      hasCompletedPayment: true,
      unlockedFeatures: {
        'prime_forum': true,
        'prime_badge': true,
        'priority_listing': true,
        'advanced_stats': true,
        'chat': true,
        'tracking': true,
        'caution': true,
        'subscription': true,
      },
    );
  }
}

/// Provider pour l'état de simulation des paiements
final paymentSimulationProvider =
    StateNotifierProvider<PaymentSimulationNotifier, PaymentSimulationState>(
  (ref) => PaymentSimulationNotifier(),
);

/// Provider pour vérifier si Prime est actif
final isPrimeActiveProvider = Provider<bool>((ref) {
  return ref.watch(paymentSimulationProvider).isPrimeActive;
});

/// Provider pour vérifier si un paiement a été complété
final hasCompletedPaymentProvider = Provider<bool>((ref) {
  return ref.watch(paymentSimulationProvider).hasCompletedPayment;
});

/// Provider pour vérifier si une fonctionnalité est débloquée
final isFeatureUnlockedProvider = Provider.family<bool, String>((ref, featureName) {
  return ref.watch(paymentSimulationProvider).unlockedFeatures[featureName] ?? false;
});
