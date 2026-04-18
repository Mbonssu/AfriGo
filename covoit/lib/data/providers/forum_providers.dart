import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client_provider.dart';
import '../repositories/forum_repository.dart';

final forumRepositoryProvider = Provider<ForumRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return ForumRepository(client);
});

/// Paramètre optionnel : catégorie ("discussion", "announcement", "tip") ou null pour tous
final forumPostsProvider =
    FutureProvider.autoDispose.family<Map<String, dynamic>, String?>((ref, category) {
  final repo = ref.watch(forumRepositoryProvider);
  return repo.getPosts(category: category);
});

final forumPostDetailProvider =
    FutureProvider.autoDispose.family<Map<String, dynamic>, String>((ref, postId) {
  final repo = ref.watch(forumRepositoryProvider);
  return repo.getPost(postId);
});
