class AppEnv {
  static const String name = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'prod',
  );

  static bool get isProd => name == 'prod';

  static const String _devBaseUrl = String.fromEnvironment(
    'AI_BACKEND_BASE_URL_DEV',
    defaultValue: 'http://localhost:8080',
  );

  static const String _prodBaseUrl = String.fromEnvironment(
    'AI_BACKEND_BASE_URL_PROD',
    defaultValue: 'https://focuslane-ai-backend-jajf6p3puq-ew.a.run.app',
  );

  static String get backendBaseUrl => isProd ? _prodBaseUrl : _devBaseUrl;
}