import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client_provider.dart';
import '../repositories/chat_repository.dart';

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return ChatRepository(client);
});

final userChatRoomsProvider =
    FutureProvider.autoDispose.family<Map<String, dynamic>, String>((ref, userId) {
  final repo = ref.watch(chatRepositoryProvider);
  return repo.getUserRooms(userId);
});

/// Paramètre : "tripId|user1Id|user2Id"
final chatRoomProvider =
    FutureProvider.autoDispose.family<Map<String, dynamic>, String>((ref, params) {
  final parts = params.split('|');
  final repo = ref.watch(chatRepositoryProvider);
  return repo.getOrCreateRoom(parts[0], parts[1], parts[2]);
});

/// Paramètre : roomId
final chatMessagesProvider =
    FutureProvider.autoDispose.family<Map<String, dynamic>, String>((ref, roomId) {
  final repo = ref.watch(chatRepositoryProvider);
  return repo.getMessages(roomId);
});
