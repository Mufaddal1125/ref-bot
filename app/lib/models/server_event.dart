/// One message off the socket. Hand-written: json_serializable has no unions,
/// so the payload stays raw and each handler reads what it needs.
class ServerEvent {
  const ServerEvent({required this.type, this.payload = const {}});

  final String type;
  final Map<String, dynamic> payload;

  factory ServerEvent.fromJson(Map<String, dynamic> json) => ServerEvent(
    type: json['type'] as String? ?? 'unknown',
    payload: json['payload'] as Map<String, dynamic>? ?? const {},
  );

  /// Sent by the server on accept, and again after every reconnect.
  static const connected = 'connected';

  /// Raised by DebateSocket itself, never by the server.
  static const disconnected = 'disconnected';

  static const debateUpdated = 'debate.updated';
  static const error = 'error';

  /// One new chat line, not the whole debate — chat is far too chatty for that.
  static const chatMessage = 'chat.message';
  static const chatDeleted = 'chat.deleted';

  /// A send this client made was refused. Nobody else hears about it.
  static const chatError = 'chat.error';

  /// Sent up, not down: the only frame a client writes to the socket.
  static const chatSend = 'chat.send';
}
