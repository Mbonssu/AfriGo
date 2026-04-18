import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../app_theme.dart';
import '../data/providers/notification_providers.dart';
import '../data/providers/journey_providers.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userIdAsync = ref.watch(currentUserIdProvider);

    return userIdAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Erreur: $e'))),
      data: (userId) {
        if (userId == null) {
          return const Scaffold(body: Center(child: Text('Connectez-vous pour voir vos notifications')));
        }
        return _NotificationsBody(userId: userId);
      },
    );
  }
}

class _NotificationsBody extends ConsumerWidget {
  final String userId;
  const _NotificationsBody({required this.userId});

  IconData _iconFor(String icon) {
    switch (icon) {
      case 'trip': return Icons.directions_car_rounded;
      case 'booking': return Icons.check_circle_rounded;
      case 'payment': return Icons.payment_rounded;
      case 'rating': return Icons.star_rounded;
      case 'promo': return Icons.local_offer_rounded;
      case 'chat': return Icons.chat_rounded;
      default: return Icons.notifications_rounded;
    }
  }

  Color _colorFor(String icon) {
    switch (icon) {
      case 'trip': return AppColors.green;
      case 'booking': return AppColors.green;
      case 'payment': return AppColors.prime;
      case 'rating': return AppColors.prime;
      case 'promo': return AppColors.green;
      case 'chat': return AppColors.green;
      default: return AppColors.green;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final notifsAsync = ref.watch(userNotificationsProvider(userId));

    // Écouter le WS : rafraîchir la liste quand une nouvelle notif arrive
    ref.listen(notificationWsProvider, (_, next) {
      next.whenData((_) {
        ref.invalidate(userNotificationsProvider(userId));
      });
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: () async {
              final repo = ref.read(notificationRepositoryProvider);
              await repo.markAllAsRead(userId);
              ref.invalidate(userNotificationsProvider(userId));
            },
            child: const Text('Tout lire',
                style: TextStyle(color: Colors.white70, fontSize: 13)),
          ),
        ],
      ),
      body: notifsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur: $e')),
        data: (response) {
          final notifs = (response['data'] as List?) ?? [];
          if (notifs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off_rounded, size: 52, color: AppColors.gray100),
                  SizedBox(height: 14),
                  Text('Aucune notification',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.gray400)),
                ],
              ),
            );
          }
          return ListView.separated(
            itemCount: notifs.length,
            separatorBuilder: (_, __) => const Divider(height: 0),
            itemBuilder: (context, i) {
              final n = notifs[i];
              final unread = !(n['is_read'] as bool? ?? false);
              final icon = n['icon'] as String? ?? 'info';
              return Container(
                color: unread ? cs.primaryContainer.withOpacity(0.3) : null,
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  leading: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: _colorFor(icon).withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(_iconFor(icon), color: _colorFor(icon), size: 20),
                  ),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(n['title'] ?? '',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: unread ? FontWeight.w700 : FontWeight.w500,
                                color: cs.onSurface)),
                      ),
                      if (unread)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(color: AppColors.green, shape: BoxShape.circle),
                        ),
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 3),
                      Text(n['body'] ?? '',
                          style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant, height: 1.4)),
                      const SizedBox(height: 4),
                      Text(_formatTime(n['created_at'] as String?),
                          style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
                    ],
                  ),
                  onTap: () async {
                    if (unread) {
                      final repo = ref.read(notificationRepositoryProvider);
                      await repo.markAsRead(n['id']);
                      ref.invalidate(userNotificationsProvider(userId));
                    }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _formatTime(String? isoDate) {
    if (isoDate == null) return '';
    try {
      final dt = DateTime.parse(isoDate);
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
      if (diff.inHours < 24) return 'Il y a ${diff.inHours}h';
      return 'Il y a ${diff.inDays}j';
    } catch (_) {
      return isoDate;
    }
  }
}
