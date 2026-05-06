import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app_theme.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client_provider.dart';
import '../../core/network/websocket_service.dart';
import '../../data/providers/chat_providers.dart';
import '../../data/providers/journey_providers.dart';
import '../../widgets/user_avatar.dart';

/// Le chat n'est accessible que si [tripConfirmed] est true.
class ChatScreen extends ConsumerStatefulWidget {
  final String driverName;
  final String? driverPhotoUrl;
  final bool isPrime;
  final bool tripConfirmed;
  final String? tripId;
  final String? otherUserId;
  final String? tripFrom;
  final String? tripTo;
  final String? tripDate;

  const ChatScreen({
    super.key,
    required this.driverName,
    this.driverPhotoUrl,
    required this.isPrime,
    this.tripConfirmed = false,
    this.tripId,
    this.otherUserId,
    this.tripFrom,
    this.tripTo,
    this.tripDate,
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final List<_Message> _messages = [];
  String? _roomId;
  String? _currentUserId;
  WebSocketService? _ws;
  StreamSubscription? _wsSub;
  final List<DateTime> _messageTimes = [];

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  @override
  void dispose() {
    _wsSub?.cancel();
    _ws?.dispose();
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    final userId = await ref.read(currentUserIdProvider.future);
    if (userId == null || widget.tripId == null || widget.otherUserId == null) return;
    _currentUserId = userId;

    try {
      final chatRepo = ref.read(chatRepositoryProvider);
      final roomData = await chatRepo.getOrCreateRoom(widget.tripId!, userId, widget.otherUserId!);
      final roomId = roomData['id']?.toString();
      if (roomId == null) return;
      _roomId = roomId;

      // Connexion WebSocket temps réel
      final tokenStorage = ref.read(tokenStorageProvider);
      final token = await tokenStorage.getAccessToken();
      if (token != null) {
        _ws = WebSocketService(url: ApiEndpoints.wsChat(roomId, token));
        _wsSub = _ws!.stream.listen((data) {
          if (data['type'] == 'new_message') {
            final m = data['message'] as Map<String, dynamic>;
            final createdAt = m['created_at'] as String? ?? '';
            String time = '';
            if (createdAt.isNotEmpty) {
              try {
                final dt = DateTime.parse(createdAt);
                time = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
              } catch (_) {}
            }
            if (mounted) {
              setState(() {
                _messages.add(_Message(
                  text: m['content'] as String? ?? '',
                  isMe: false,
                  time: time,
                ));
              });
              _scrollToBottom();
            }
          }
        });
        await _ws!.connect();
      }

      final msgData = await chatRepo.getMessages(roomId);
      final msgs = (msgData['data'] as List?) ?? [];
      setState(() {
        _messages.clear();
        for (final m in msgs) {
          final senderId = m['sender_id']?.toString() ?? '';
          final createdAt = m['created_at'] as String? ?? '';
          String time = '';
          if (createdAt.isNotEmpty) {
            try {
              final dt = DateTime.parse(createdAt);
              time = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
            } catch (_) {}
          }
          _messages.add(_Message(
            text: m['content'] as String? ?? '',
            isMe: senderId == userId,
            time: time,
          ));
        }
      });
      _scrollToBottom();
    } catch (_) {
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage() async {
    if (_msgCtrl.text.trim().isEmpty || _roomId == null || _currentUserId == null) return;
    final text = _msgCtrl.text.trim();
    if (text.length > 1000) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Message trop long (max. 1000 caractères).')),
      );
      return;
    }
    // Anti-spam : max 5 messages en 10 secondes
    final nowDt = DateTime.now();
    _messageTimes.removeWhere((t) => nowDt.difference(t).inSeconds > 10);
    if (_messageTimes.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Envoi trop rapide. Veuillez ralentir.')),
      );
      return;
    }
    _messageTimes.add(nowDt);
    final now = TimeOfDay.now();
    final timeStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    setState(() {
      _messages.add(_Message(text: text, isMe: true, time: timeStr));
      _msgCtrl.clear();
    });
    _scrollToBottom();

    try {
      final chatRepo = ref.read(chatRepositoryProvider);
      await chatRepo.sendMessage(_roomId!, senderId: _currentUserId!, content: text);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final initials = widget.driverName.split(' ').map((e) => e[0]).take(2).join();

    // ── Accès refusé si pas de trajet confirmé ──────────────────
    if (!widget.tripConfirmed) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chat')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80, height: 80,
                  decoration: const BoxDecoration(
                    color: AppColors.coralLight,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.lock_rounded,
                      color: AppColors.coral, size: 40),
                ),
                const SizedBox(height: 20),
                Text('Chat non disponible',
                    style: TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w700,
                        color: cs.onSurface)),
                const SizedBox(height: 12),
                Text(
                  'Le chat est uniquement disponible lorsque vous partagez un trajet confirmé avec ce chauffeur.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 14, color: cs.onSurfaceVariant, height: 1.6),
                ),
                const SizedBox(height: 28),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Retour'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // ── Chat actif ───────────────────────────────────────────────
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            PrimeUserAvatar(
              photoUrl: widget.driverPhotoUrl,
              initials: initials,
              radius: 18,
              isPrime: widget.isPrime,
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.driverName,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700)),
                Row(
                  children: [
                    Container(
                      width: 7, height: 7,
                      decoration: const BoxDecoration(
                          color: Colors.white38, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 4),
                    const Text('Chat',
                        style: TextStyle(fontSize: 11, color: Colors.white70)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Bandeau trajet partagé
          if (widget.tripFrom != null && widget.tripTo != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: cs.primaryContainer,
              child: Row(
                children: [
                  Icon(Icons.verified_rounded, size: 15, color: cs.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Trajet partagé confirmé · ${widget.tripFrom} → ${widget.tripTo}${widget.tripDate != null ? ' · ${widget.tripDate}' : ''}',
                      style: TextStyle(
                          fontSize: 12,
                          color: cs.primary,
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, i) {
                final msg = _messages[i];
                return Align(
                  alignment: msg.isMe
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Column(
                    crossAxisAlignment: msg.isMe
                        ? CrossAxisAlignment.end
                        : CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(bottom: 4),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        constraints: BoxConstraints(
                            maxWidth:
                                MediaQuery.of(context).size.width * 0.72),
                        decoration: BoxDecoration(
                          color: msg.isMe ? AppColors.green : cs.surface,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(16),
                            topRight: const Radius.circular(16),
                            bottomLeft:
                                Radius.circular(msg.isMe ? 16 : 4),
                            bottomRight:
                                Radius.circular(msg.isMe ? 4 : 16),
                          ),
                          border: msg.isMe
                              ? null
                              : Border.all(
                                  color: cs.outline.withOpacity(0.3),
                                  width: 0.5),
                        ),
                        child: Text(msg.text,
                            style: TextStyle(
                                fontSize: 14,
                                color: msg.isMe
                                    ? Colors.white
                                    : cs.onSurface,
                                height: 1.4)),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(
                            bottom: 10, left: 4, right: 4),
                        child: Text(msg.time,
                            style: TextStyle(
                                fontSize: 10,
                                color: cs.onSurfaceVariant)),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: cs.surface,
              border: Border(
                  top: BorderSide(
                      color: cs.outline.withOpacity(0.3), width: 0.5)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _msgCtrl,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                    decoration: InputDecoration(
                      hintText: 'Votre message...',
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      fillColor: cs.surfaceContainerHighest,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _sendMessage,
                  child: Container(
                    width: 44, height: 44,
                    decoration: const BoxDecoration(
                        color: AppColors.green, shape: BoxShape.circle),
                    child: const Icon(Icons.send_rounded,
                        color: Colors.white, size: 18),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Message {
  final String text;
  final bool isMe;
  final String time;
  const _Message({required this.text, required this.isMe, required this.time});
}
