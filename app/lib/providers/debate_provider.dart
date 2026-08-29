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
    // TODO(step 6): post the argument, then reload the debate so the new
    // history and the new turn arrive together.
    throw UnimplementedError();
  }

  Future<void> start() async {
    // TODO(step 6)
    throw UnimplementedError();
  }

  Future<void> end() async {
    // TODO(step 6)
    throw UnimplementedError();
  }

  void clear() {
    _debate = null;
    _error = null;
    notifyListeners();
  }

  /// Worked example: every action runs through here, so loading and error
  /// handling live in one place.
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
