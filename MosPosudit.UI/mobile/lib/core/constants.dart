const String _defaultApiUrl = 'http://10.0.2.2:5001/api';
const String _apiUrlFromEnv = String.fromEnvironment('API_URL', defaultValue: _defaultApiUrl);

String getApiBaseUrl() {
  return _apiUrlFromEnv;
}

String get apiBaseUrl => getApiBaseUrl();

const String appName = 'MosPosudit';
const String appVersion = '1.0.0';

const double defaultPadding = 16.0;
const double defaultBorderRadius = 12.0;

const String unauthorizedMessage = 'You are not authorized for this action';
const String serverErrorMessage = 'Server error'; 