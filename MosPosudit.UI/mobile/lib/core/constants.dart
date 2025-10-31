import 'dart:io';
import 'package:flutter/foundation.dart';

// API Configuration
// Your computer's IP address (update this if it changes)
const String _realDeviceIp = '192.168.0.57';
const String _emulatorIp = '10.0.2.2';
const int _apiPort = 5001;

// Automatically detect if running on emulator or real device
String getApiBaseUrl() {
  if (Platform.isAndroid) {
    // Check environment variable first (for manual override)
    // Usage: flutter run --dart-define=API_IP=192.168.0.57
    final overrideIp = Platform.environment['API_IP'] ?? 
                       (const String.fromEnvironment('API_IP', defaultValue: ''));
    if (overrideIp.isNotEmpty) {
      print('Using API IP from environment: $overrideIp');
      return 'http://$overrideIp:$_apiPort/api';
    }
    
    // Try to detect emulator via ANDROID_SERIAL
    // Emulators have serial numbers like "emulator-5554"
    final androidSerial = Platform.environment['ANDROID_SERIAL'] ?? '';
    final isEmulator = androidSerial.toLowerCase().contains('emulator');
    
    if (isEmulator) {
      print('Detected emulator (serial: $androidSerial), using: $_emulatorIp');
      return 'http://$_emulatorIp:$_apiPort/api';
    } else {
      // Real device - use computer's IP
      print('Detected real device (serial: $androidSerial), using: $_realDeviceIp');
      return 'http://$_realDeviceIp:$_apiPort/api';
    }
  }
  
  // Fallback for non-Android platforms
  print('Non-Android platform, using real device IP: $_realDeviceIp');
  return 'http://$_realDeviceIp:$_apiPort/api';
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