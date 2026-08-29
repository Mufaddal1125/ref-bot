/// Where the backend lives. The only thing that changes per device.
class Env {
  const Env._();

  static const apiBase = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8000',
  );

  static String get wsBase => apiBase.replaceFirst('http', 'ws');
}
