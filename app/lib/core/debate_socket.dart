import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/status.dart' as status;
import 'package:web_socket_channel/web_socket_channel.dart';

import '../models/server_event.dart';
import 'env.dart';

/// The consumer closes with this when the token does not belong to the debate.
const closeUnauthorized = 4401;

/// Holds one socket to a debate open, reconnecting with backoff when it drops.
///
/// Listen-only: changes go to the REST API, and arrive back here as events.
class DebateSocket {
  DebateSocket({required this.debateId, required this.token});

  final String debateId;
  final String token;

  final _events = StreamController<ServerEvent>.broadcast();
  WebSocketChannel? _channel;
  Timer? _retry;
  int _attempt = 0;
  bool _disposed = false;

  Stream<ServerEvent> get events => _events.stream;

  void connect() {
    if (_disposed) {
      return;
    }
    _retry?.cancel();

    // Browsers cannot set headers on a WebSocket, so the token goes in the query.
    final channel = WebSocketChannel.connect(
      Uri.parse('${Env.wsBase}/ws/debate/$debateId/?token=$token'),
    );
    _channel = channel;

    channel.stream.listen(
      _onMessage,
      onDone: _reconnectLater,
      onError: (Object _) => _reconnectLater(),
      cancelOnError: true,
    );

    // A refused upgrade lands on ready as well as on the stream. Without this
    // it escapes as an unhandled error and takes the app down.
    unawaited(channel.ready.catchError((Object _) {}));
  }

  Future<void> dispose() async {
    _disposed = true;
    _retry?.cancel();
    // A client may only send 1000 or 3000-4999; 1001 is rejected.
    await _channel?.sink.close(status.normalClosure);
    await _events.close();
  }

  void _onMessage(dynamic message) {
    _attempt = 0;
    final json = jsonDecode(message as String) as Map<String, dynamic>;
    _events.add(ServerEvent.fromJson(json));
  }

  void _reconnectLater() {
    if (_disposed) {
      return;
    }
    if (_channel?.closeCode == closeUnauthorized) {
      _events.add(
        const ServerEvent(
          type: ServerEvent.error,
          payload: {'message': 'This session is no longer valid.'},
        ),
      );
      return;
    }
    _events.add(const ServerEvent(type: ServerEvent.disconnected));

    // 1s, 2s, 4s, 8s, then every 16s.
    final wait = Duration(seconds: 1 << _attempt);
    _attempt = (_attempt + 1).clamp(0, 4);
    _retry = Timer(wait, connect);
  }
}
