import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';

class ForumRepository {
  final ApiClient _client;

  ForumRepository(this._client);

  Future<Map<String, dynamic>> getPosts({String? category, int limit = 50}) async {
    final params = <String, dynamic>{'limit': limit};
    if (category != null) params['category'] = category;
    return await _client.get<Map<String, dynamic>>(
      ApiEndpoints.forumPosts,
      queryParameters: params,
    );
  }

  Future<Map<String, dynamic>> createPost({
    required String authorId,
    required String authorName,
    String? authorAvatar,
    required String category,
    required String content,
  }) async {
    return await _client.post<Map<String, dynamic>>(
      ApiEndpoints.forumPosts,
      data: {
        'author_id': authorId,
        'author_name': authorName,
        'author_avatar': authorAvatar,
        'category': category,
        'content': content,
      },
    );
  }

  Future<Map<String, dynamic>> getPost(String postId) async {
    return await _client.get<Map<String, dynamic>>(
      ApiEndpoints.forumPostById(postId),
    );
  }

  Future<Map<String, dynamic>> addComment({
    required String postId,
    required String authorId,
    required String authorName,
    required String content,
  }) async {
    return await _client.post<Map<String, dynamic>>(
      ApiEndpoints.forumPostComments(postId),
      data: {
        'author_id': authorId,
        'author_name': authorName,
        'content': content,
      },
    );
  }

  Future<Map<String, dynamic>> toggleLike(String postId, String userId) async {
    return await _client.post<Map<String, dynamic>>(
      ApiEndpoints.forumPostLike(postId),
      queryParameters: {'user_id': userId},
    );
  }
}
