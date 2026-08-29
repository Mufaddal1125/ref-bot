import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/api_client.dart';
import '../core/api_exception.dart';
import '../models/enums.dart';
import '../models/session.dart';

/// Who this device is in a debate. Survives a refresh or a hot restart.
class SessionProvider extends ChangeNotifier {
  SessionProvider(this._api);

  final ApiClient _api;

  String? _debateId;
  Role? _role;
  bool _restored = false;
  bool _isBusy = false;
  String? _error;

  String? get debateId => _debateId;
  Role? get role => _role;
  bool get restored => _restored;
  bool get isBusy => _isBusy;
  String? get error => _error;
  bool get hasSession => _debateId != null && _api.token != null;

  Future<void> restore() async {
    // TODO(step 6): read the token, debate id and role back out of
    // SharedPreferences so a browser refresh does not sign you out.
    _restored = true;
    notifyListeners();
  }

  Future<void> create({required String topic, required String displayName}) =>
      _open(() => _api.createDebate(topic: topic, displayName: displayName));

  Future<void> join({
    required String joinCode,
    required String displayName,
    required Role role,
  }) => _open(
    () => _api.joinDebate(
      joinCode: joinCode,
      displayName: displayName,
      role: role,
    ),
  );

  Future<void> leave() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_debateKey);
    await prefs.remove(_roleKey);

    _api.token = null;
    _debateId = null;
    _role = null;
    notifyListeners();
  }

  Future<void> _open(Future<Session> Function() call) async {
    _isBusy = true;
    _error = null;
    notifyListeners();

    try {
      await call();
      // TODO(step 6): keep the session's token, debate id and role here, and
      // write the same three values into SharedPreferences.
      throw UnimplementedError();
    } on ApiException catch (e) {
      _error = e.message;
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  static const _tokenKey = 'token';
  static const _debateKey = 'debate_id';
  static const _roleKey = 'role';
}
