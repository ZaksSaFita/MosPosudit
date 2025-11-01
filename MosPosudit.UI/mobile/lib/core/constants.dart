// API Configuration
// Uses --dart-define=API_URL=http://10.0.2.2:5001/api for Android emulator (Docker port)
// Or use --dart-define=API_URL=http://YOUR_IP:5001/api for physical device
// For local development (non-Docker): use port 5000
const String _defaultApiUrl = 'http://10.0.2.2:5001/api';
const String _apiUrlFromEnv = String.fromEnvironment('API_URL', defaultValue: _defaultApiUrl);

// Get API base URL - uses dart-define or default
String getApiBaseUrl() {
  final url = _apiUrlFromEnv;
  print('Using API URL: $url');
  return url;
}

// Get API base URL (computed at runtime)
String get apiBaseUrl => getApiBaseUrl();

// App Configuration
const String appName = 'MosPosudit Mobile';
const String appVersion = '1.0.0';

// UI Configuration
const double defaultPadding = 16.0;
const double defaultBorderRadius = 12.0;

// Error Messages
const String unauthorizedMessage = 'You are not authorized for this action';
const String serverErrorMessage = 'Server error'; 