const String _defaultApiUrl = 'http://localhost:5001/api';
const String apiBaseUrl = String.fromEnvironment('API_URL', defaultValue: _defaultApiUrl);

const String appName = 'MosPosudit';
const String appVersion = '1.0.0';

const double defaultPadding = 16.0;
const double defaultBorderRadius = 12.0;

const String networkErrorMessage = 'Greška pri povezivanju sa serverom';
const String unauthorizedMessage = 'Niste autorizovani za ovu akciju';
const String serverErrorMessage = 'Greška na serveru';

const String loginSuccessMessage = 'Uspešno ste se prijavili!';
const String logoutSuccessMessage = 'Uspešno ste se odjavili!'; 