import 'package:dio/dio.dart';

import '../models/chat_message.dart';
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

  Future<Debate> vote(String debateId, Side choice) async => Debate.fromJson(
    await _post('/api/debates/$debateId/vote/', {'choice': choice.wire}),
  );

  Future<Debate> closeDebate(String debateId) async =>
      Debate.fromJson(await _post('/api/debates/$debateId/close/', const {}));

  /// The chat backlog. New lines arrive on the socket; this is what came before.
  Future<List<ChatMessage>> fetchChatMessages(String debateId) async {
    final response = await _send(
      () => _dio.get<List<dynamic>>('/api/debates/$debateId/chat/'),
    );
    return (response.data ?? const [])
        .map((row) => ChatMessage.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  /// Moderator only. The message stays in the list, with its words removed.
  Future<void> deleteChatMessage(String debateId, String messageId) => _send(
    () => _dio.delete<void>('/api/debates/$debateId/chat/$messageId/'),
  );

  Future<Map<String, dynamic>> _get(String path) =>
      _read(() => _dio.get<Map<String, dynamic>>(path));

  Future<Map<String, dynamic>> _post(String path, Map<String, dynamic> body) =>
      _read(() => _dio.post<Map<String, dynamic>>(path, data: body));

  Future<Map<String, dynamic>> _read(
    Future<Response<Map<String, dynamic>>> Function() send,
  ) async => (await _send(send)).data ?? const {};

  /// Turns dio's failures into the one exception the providers know about.
  Future<Response<T>> _send<T>(Future<Response<T>> Function() send) async {
    try {
      return await send();
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
