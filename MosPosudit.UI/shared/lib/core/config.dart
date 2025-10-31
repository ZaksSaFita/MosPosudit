class AppConfig {
  final String apiBaseUrl;

  AppConfig({required this.apiBaseUrl});

  static AppConfig? _instance;
  static AppConfig get instance => _instance ??= AppConfig(apiBaseUrl: 'http://localhost:5001/api');
  static set instance(AppConfig value) => _instance = value;
}

