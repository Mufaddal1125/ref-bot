import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/api_client.dart';
import '../core/api_exception.dart';
import '../core/debate_socket.dart';
import '../models/chat_message.dart';
import '../models/debate.dart';
import '../models/enums.dart';
import '../models/server_event.dart';

/// The debate on screen. Actions go out over HTTP; state comes back on the socket.
///
/// Chat lives here too, because it shares the socket and the debate id. It is
/// kept in its own fields and its own error, so a rate-limited "slow down" never
/// lands in the banner the debate uses.
class DebateProvider extends ChangeNotifier {
  DebateProvider(this._api);

  final ApiClient _api;

  Debate? _debate;
  bool _isLoading = false;
  bool _isConnected = false;
  String? _error;

  DebateSocket? _socket;
  StreamSubscription<ServerEvent>? _subscription;
  String? _debateId;
  Side? _myVote;

  final List<ChatMessage> _chatMessages = [];
  String? _chatError;
  int _unreadChat = 0;
  bool _chatIsOpen = false;

  Debate? get debate => _debate;
  bool get isLoading => _isLoading;
  bool get isConnected => _isConnected;
  String? get error => _error;
  Side? get myVote => _myVote;
  List<ChatMessage> get chatMessages => _chatMessages;
  String? get chatError => _chatError;
  int get unreadChat => _unreadChat;

  void connect(String debateId) {
    _debateId = debateId;
    _socket = DebateSocket(debateId: debateId, token: _api.token ?? '');
    _subscription = _socket!.events.listen(_onEvent);
    _socket!.connect();
  }

  Future<void> submitArgument(String body) =>
      _act((debateId) => _api.submitArgument(debateId, body));

  Future<void> start() => _act(_api.startDebate);

  Future<void> end() => _act(_api.endDebate);

  Future<void> vote(Side choice) async {
    await _act((debateId) => _api.vote(debateId, choice));
    if (_error == null) {
      _myVote = choice;
      notifyListeners();
    }
  }

  Future<void> close() => _act(_api.closeDebate);

  /// Straight up the socket. The server broadcasts it back to everyone, this
  /// client included, so there is no optimistic copy to reconcile.
  void sendChat(String body) {
    final text = body.trim();
    if (text.isEmpty) {
      return;
    }
    if (_socket?.send(ServerEvent.chatSend, {'body': text}) ?? false) {
      return;
    }
    _chatError = 'Not connected — that message was not sent.';
    notifyListeners();
  }

  /// Moderator only; the server refuses anyone else. Over HTTP, because a
  /// removal is a moderation decision and wants a status code, not a hope.
  Future<void> deleteChatMessage(String messageId) async {
    final debateId = _debateId;
    if (debateId == null) {
      return;
    }
    try {
      await _api.deleteChatMessage(debateId, messageId);
    } on ApiException catch (e) {
      _chatError = e.message;
      notifyListeners();
    }
  }

  /// The panel says when it is on screen, so the badge counts only what was
  /// genuinely missed.
  void setChatOpen(bool isOpen) {
    _chatIsOpen = isOpen;
    if (isOpen) {
      _unreadChat = 0;
    }
    notifyListeners();
  }

  void clearChatError() {
    if (_chatError == null) {
      return;
    }
    _chatError = null;
    notifyListeners();
  }

  Future<void> disconnect() async {
    await _subscription?.cancel();
    await _socket?.dispose();
    _subscription = null;
    _socket = null;
    _debate = null;
    _myVote = null;
    _error = null;
    _isConnected = false;
    _chatMessages.clear();
    _chatError = null;
    _unreadChat = 0;
    _chatIsOpen = false;
  }

  /// Actions only report failure. The new state arrives as a broadcast, so
  /// nothing here writes to _debate and the two paths cannot drift.
  Future<void> _act(Future<void> Function(String debateId) call) async {
    final debateId = _debateId;
    if (debateId == null) {
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await call(debateId);
    } on ApiException catch (e) {
      _error = e.message;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _onEvent(ServerEvent event) {
    switch (event.type) {
      case ServerEvent.connected:
        _isConnected = true;
        _load();
      case ServerEvent.disconnected:
        _isConnected = false;
        notifyListeners();
      case ServerEvent.debateUpdated:
        _debate = Debate.fromJson(event.payload);
        _error = null;
        notifyListeners();
      case ServerEvent.chatMessage:
        _appendChat(ChatMessage.fromJson(event.payload));
      case ServerEvent.chatDeleted:
        _markChatRemoved(event.payload['id'] as String?);
      case ServerEvent.chatError:
        // Only this client's send failed; the room does not need telling.
        _chatError = event.payload['message'] as String?;
        notifyListeners();
      case ServerEvent.error:
        _error = event.payload['message'] as String?;
        notifyListeners();
    }
  }

  void _appendChat(ChatMessage message) {
    // A backlog fetch and a socket push can cross on a reconnect and deliver
    // the same line twice.
    if (_chatMessages.any((m) => m.id == message.id)) {
      return;
    }

    _chatMessages.add(message);
    if (_chatMessages.length > _chatBacklog) {
      _chatMessages.removeRange(0, _chatMessages.length - _chatBacklog);
    }
    if (!_chatIsOpen) {
      _unreadChat++;
    }
    notifyListeners();
  }

  void _markChatRemoved(String? id) {
    final at = _chatMessages.indexWhere((m) => m.id == id);
    if (at == -1) {
      return;
    }
    // Replaced in place, not dropped: the gap has to stay visible or the room
    // sees messages vanishing for no stated reason.
    _chatMessages[at] = _chatMessages[at].removed();
    notifyListeners();
  }

  /// Runs on connect and on every reconnect, so a dropped socket resyncs itself.
  Future<void> _load() async {
    final debateId = _debateId;
    if (debateId == null) {
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      _debate = await _api.fetchDebate(debateId);
      // Only this HTTP path carries my_vote; socket pushes leave it null.
      _myVote = _debate?.myVote ?? _myVote;
      _error = null;
    } on ApiException catch (e) {
      _error = e.message;
    } finally {
      _isLoading = false;
      notifyListeners();
    }

    await _loadChat(debateId);
  }

  /// Fetched whole rather than merged: a socket that was away has no way to say
  /// which lines it missed, and the tail the server keeps is small enough.
  Future<void> _loadChat(String debateId) async {
    try {
      final messages = await _api.fetchChatMessages(debateId);
      _chatMessages
        ..clear()
        ..addAll(messages);
      _chatError = null;
    } on ApiException catch (e) {
      // Its own error: a chat that will not load must not read as a debate
      // that will not load.
      _chatError = e.message;
    }
    notifyListeners();
  }

  /// Matches the tail the server keeps, so scrollback is the same everywhere.
  static const _chatBacklog = 200;
}
