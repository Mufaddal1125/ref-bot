import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/api_client.dart';
import '../core/api_exception.dart';
import '../core/debate_socket.dart';
import '../models/debate.dart';
import '../models/enums.dart';
import '../models/server_event.dart';

/// The debate on screen. Actions go out over HTTP; state comes back on the socket.
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

  Debate? get debate => _debate;
  bool get isLoading => _isLoading;
  bool get isConnected => _isConnected;
  String? get error => _error;
  Side? get myVote => _myVote;

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
    // TODO(step 5): cast the vote, then remember the choice so this device
    // shows the result instead of the ballot again.
    throw UnimplementedError();
  }

  Future<void> close() async {
    // TODO(step 5)
    throw UnimplementedError();
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
      case ServerEvent.error:
        _error = event.payload['message'] as String?;
        notifyListeners();
    }
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
      // TODO(step 5): only this HTTP path carries my_vote. A socket push leaves
      // it null, so keep what is already here rather than clearing it.
      _error = null;
    } on ApiException catch (e) {
      _error = e.message;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
