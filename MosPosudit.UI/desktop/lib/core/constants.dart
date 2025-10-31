// API Configuration
// Uses --dart-define=API_URL=http://localhost:5001/api
// Or use --dart-define=API_URL=http://YOUR_IP:5001/api if needed
const String _defaultApiUrl = 'http://localhost:5001/api';
const String apiBaseUrl = String.fromEnvironment('API_URL', defaultValue: _defaultApiUrl);

// App Configuration
const String appName = 'MosPosudit Desktop';
const String appVersion = '1.0.0';

// UI Configuration
const double defaultPadding = 16.0;
const double defaultBorderRadius = 12.0;

// Error Messages
const String networkErrorMessage = 'Greška pri povezivanju sa serverom';
const String unauthorizedMessage = 'Niste autorizovani za ovu akciju';
const String serverErrorMessage = 'Greška na serveru';

// Success Messages
const String loginSuccessMessage = 'Uspešno ste se prijavili!';
const String logoutSuccessMessage = 'Uspešno ste se odjavili!'; 