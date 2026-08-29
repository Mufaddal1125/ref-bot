import 'package:flutter/foundation.dart';
import 'package:refbot_core/refbot_core.dart';
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
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    final wire = prefs.getString(_roleKey);

    if (token != null && wire != null) {
      _api.token = token;
      _debateId = prefs.getString(_debateKey);
      _role = fromWire(Role.values, wire);
    }
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
      final session = await call();
      _api.token = session.token;
      _debateId = session.debate.id;
      _role = session.participant.role;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, _api.token!);
      await prefs.setString(_debateKey, _debateId!);
      await prefs.setString(_roleKey, _role!.wire);
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
