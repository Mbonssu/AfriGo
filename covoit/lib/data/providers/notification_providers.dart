import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client_provider.dart';
import '../../core/network/websocket_service.dart';
import '../repositories/notification_repository.dart';
import 'journey_providers.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return NotificationRepository(client);
});

final userNotificationsProvider =
    FutureProvider.autoDispose.family<Map<String, dynamic>, String>((ref, userId) {
  final repo = ref.watch(notificationRepositoryProvider);
  return repo.getUserNotifications(userId);
});

/// Compteur de notifications non lues, mis à jour en temps réel via WebSocket.
final unreadNotificationsCountProvider = StateProvider<int>((ref) => 0);

/// Stream global des notifications en temps réel.
/// Se connecte au WebSocket dès que l'utilisateur est authentifié.
/// Reste ouvert tant que le provider est actif (app au premier plan).
final notificationWsProvider = StreamProvider.autoDispose<Map<String, dynamic>>((ref) {
  final controller = StreamController<Map<String, dynamic>>();

  Future<void> connect() async {
    final userId = await ref.read(currentUserIdProvider.future);
    if (userId == null) return;

    final tokenStorage = ref.read(tokenStorageProvider);
    final token = await tokenStorage.getAccessToken();
    if (token == null) return;

    final ws = WebSocketService(url: ApiEndpoints.wsNotifications(token));
    ws.stream.listen(
      (data) {
        if (data['type'] == 'new_notification') {
          controller.add(data);
          // Incrémenter le compteur de non-lues
          ref.read(unreadNotificationsCountProvider.notifier).state++;
        }
      },
      onError: (e) => controller.addError(e),
    );
    await ws.connect();

    ref.onDispose(() {
      ws.dispose();
    });
  }

  connect();
  return controller.stream;
});

