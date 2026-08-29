import 'package:dio/dio.dart';

import '../models/debate.dart';
import '../models/enums.dart';
import '../models/session.dart';
import 'api_exception.dart';
import 'env.dart';

/// Every HTTP call the app makes. Providers use it; widgets never do.
class ApiClient {
  ApiClient({Dio? dio}) : _dio = dio ?? Dio() {
    _dio.options.baseUrl = Env.apiBase;
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (token != null) {
            options.headers['Authorization'] = 'Participant $token';
          }
          handler.next(options);
        },
      ),
    );
  }

  final Dio _dio;

  String? token;

  Future<Session> createDebate({
    required String topic,
    required String displayName,
  }) async {
    final json = await _post('/api/debates/', {
      'topic': topic,
      'display_name': displayName,
    });
    return Session.fromJson(json);
  }

  Future<Session> joinDebate({
    required String joinCode,
    required String displayName,
    required Role role,
  }) async {
    final json = await _post('/api/debates/join/', {
      'join_code': joinCode,
      'display_name': displayName,
      'role': role.wire,
    });
    return Session.fromJson(json);
  }

  Future<Debate> fetchDebate(String debateId) async =>
      Debate.fromJson(await _get('/api/debates/$debateId/'));

  Future<void> submitArgument(String debateId, String body) =>
      _post('/api/debates/$debateId/arguments/', {'body': body});

  Future<Debate> startDebate(String debateId) async =>
      Debate.fromJson(await _post('/api/debates/$debateId/start/', const {}));

  Future<Debate> endDebate(String debateId) async =>
      Debate.fromJson(await _post('/api/debates/$debateId/end/', const {}));

  Future<Map<String, dynamic>> _get(String path) =>
      _read(() => _dio.get<Map<String, dynamic>>(path));

  Future<Map<String, dynamic>> _post(String path, Map<String, dynamic> body) =>
      _read(() => _dio.post<Map<String, dynamic>>(path, data: body));

  /// Turns dio's failures into the one exception the providers know about.
  Future<Map<String, dynamic>> _read(
    Future<Response<Map<String, dynamic>>> Function() send,
  ) async {
    try {
      final response = await send();
      return response.data ?? const {};
    } on DioException catch (e) {
      final json = e.response?.data;
      if (json is Map) {
        throw ApiException(
          status: e.response?.statusCode ?? 0,
          code: json['code'] as String? ?? 'error',
          message: json['message'] as String? ?? 'Something went wrong.',
        );
      }
      // No response body at all: the server is unreachable, not unhappy.
      throw ApiException(
        status: e.response?.statusCode ?? 0,
        code: 'unreachable',
        message: 'Cannot reach the server.',
      );
    }
  }
}
