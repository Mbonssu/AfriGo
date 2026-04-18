import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client_provider.dart';
import '../repositories/subscription_repository.dart';

final subscriptionRepositoryProvider = Provider<SubscriptionRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return SubscriptionRepository(client);
});

final subscriptionPlansProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) {
  final repo = ref.watch(subscriptionRepositoryProvider);
  return repo.getPlans();
});

final userSubscriptionProvider =
    FutureProvider.autoDispose.family<Map<String, dynamic>, String>((ref, userId) {
  final repo = ref.watch(subscriptionRepositoryProvider);
  return repo.getUserSubscription(userId);
});
