import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';

class ChatRepository {
  final ApiClient _client;

  ChatRepository(this._client);

  Future<Map<String, dynamic>> getOrCreateRoom(String tripId, String user1, String user2) async {
    return await _client.get<Map<String, dynamic>>(
      ApiEndpoints.chatRoom(tripId, user1, user2),
    );
  }

  Future<Map<String, dynamic>> getMessages(String roomId, {int limit = 50}) async {
    return await _client.get<Map<String, dynamic>>(
      ApiEndpoints.chatMessages(roomId),
      queryParameters: {'limit': limit},
    );
  }

  Future<Map<String, dynamic>> sendMessage(String roomId, {required String senderId, required String content}) async {
    return await _client.post<Map<String, dynamic>>(
      ApiEndpoints.sendChatMessage(roomId),
      data: {'sender_id': senderId, 'content': content},
    );
  }

  Future<void> markRead(String roomId, String userId) async {
    await _client.put<Map<String, dynamic>>(
      ApiEndpoints.markChatRead(roomId, userId),
    );
  }

  Future<Map<String, dynamic>> getUserRooms(String userId) async {
    return await _client.get<Map<String, dynamic>>(
      ApiEndpoints.userChatRooms(userId),
    );
  }
}
