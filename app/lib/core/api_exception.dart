/// A failure the backend described: every error response carries a code and a message.
class ApiException implements Exception {
  const ApiException({
    required this.status,
    required this.code,
    required this.message,
  });

  final int status;
  final String code;
  final String message;

  @override
  String toString() => message;
}
