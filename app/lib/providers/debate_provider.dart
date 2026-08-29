import 'package:flutter/foundation.dart';

import '../core/api_client.dart';
import '../core/api_exception.dart';
import '../models/debate.dart';

/// The debate on screen: its state, and the actions that change it.
class DebateProvider extends ChangeNotifier {
  DebateProvider(this._api);

  final ApiClient _api;

  Debate? _debate;
  bool _isLoading = false;
  String? _error;

  Debate? get debate => _debate;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> refresh(String debateId) =>
      _run(() => _api.fetchDebate(debateId));

  Future<void> submitArgument(String body) async {
    final debateId = _debate?.id;
    if (debateId == null) {
      return;
    }
    await _run(() async {
      await _api.submitArgument(debateId, body);
      return _api.fetchDebate(debateId);
    });
  }

  Future<void> start() async {
    final debateId = _debate?.id;
    if (debateId != null) {
      await _run(() => _api.startDebate(debateId));
    }
  }

  Future<void> end() async {
    final debateId = _debate?.id;
    if (debateId != null) {
      await _run(() => _api.endDebate(debateId));
    }
  }

  void clear() {
    _debate = null;
    _error = null;
    notifyListeners();
  }

  Future<void> _run(Future<Debate> Function() call) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _debate = await call();
    } on ApiException catch (e) {
      _error = e.message;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
