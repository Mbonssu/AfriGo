import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Service WebSocket réutilisable avec reconnexion automatique.
///
/// Usage :
/// ```dart
/// final ws = WebSocketService(url);
/// ws.stream.listen((data) => print(data));
/// await ws.connect();
/// // ...
/// ws.dispose();
/// ```
class WebSocketService {
  final String url;
  final Duration reconnectDelay;

  WebSocketChannel? _channel;
  final _controller = StreamController<Map<String, dynamic>>.broadcast();
  Timer? _reconnectTimer;
  bool _disposed = false;
  bool _connected = false;

  WebSocketService({
    required this.url,
    this.reconnectDelay = const Duration(seconds: 3),
  });

  /// Stream de messages JSON décodés.
  Stream<Map<String, dynamic>> get stream => _controller.stream;

  /// Indique si la connexion est active.
  bool get isConnected => _connected;

  /// Établir la connexion WebSocket.
  Future<void> connect() async {
    if (_disposed) return;

    try {
      final uri = Uri.parse(url);
      _channel = WebSocketChannel.connect(uri);
      await _channel!.ready;
      _connected = true;
      debugPrint('[WS] Connecté à $url');

      _channel!.stream.listen(
        (data) {
          try {
            final decoded = jsonDecode(data as String) as Map<String, dynamic>;
            _controller.add(decoded);
          } catch (e) {
            debugPrint('[WS] Erreur de décodage: $e');
          }
        },
        onDone: () {
          _connected = false;
          debugPrint('[WS] Connexion fermée');
          _scheduleReconnect();
        },
        onError: (error) {
          _connected = false;
          debugPrint('[WS] Erreur: $error');
          _scheduleReconnect();
        },
      );
    } catch (e) {
      _connected = false;
      debugPrint('[WS] Erreur de connexion: $e');
      _scheduleReconnect();
    }
  }

  /// Envoyer un message JSON (ex: typing indicator).
  void send(Map<String, dynamic> data) {
    if (_connected && _channel != null) {
      _channel!.sink.add(jsonEncode(data));
    }
  }

  void _scheduleReconnect() {
    if (_disposed) return;
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(reconnectDelay, () {
      debugPrint('[WS] Tentative de reconnexion...');
      connect();
    });
  }

  /// Fermer la connexion et libérer les ressources.
  void dispose() {
    _disposed = true;
    _reconnectTimer?.cancel();
    _channel?.sink.close();
    _controller.close();
  }
}
