import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client_provider.dart';
import '../repositories/caution_repository.dart';

final cautionRepositoryProvider = Provider<CautionRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return CautionRepository(client);
});

final userCautionsProvider =
    FutureProvider.autoDispose.family<Map<String, dynamic>, String>((ref, userId) {
  final repo = ref.watch(cautionRepositoryProvider);
  return repo.getUserCautions(userId);
});

final cautionSummaryProvider =
    FutureProvider.autoDispose.family<Map<String, dynamic>, String>((ref, userId) {
  final repo = ref.watch(cautionRepositoryProvider);
  return repo.getSummary(userId);
});
