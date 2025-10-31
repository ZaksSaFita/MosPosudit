// API Configuration
// Using emulator IP address (10.0.2.2 maps to host's localhost)
const String _apiHost = '10.0.2.2';
const int _apiPort = 5001;

// Get API base URL - always uses emulator IP
String getApiBaseUrl() {
  final url = 'http://$_apiHost:$_apiPort/api';
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