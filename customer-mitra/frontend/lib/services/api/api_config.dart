import 'package:flutter/foundation.dart';

/// API Configuration class for base URL management
class ApiConfig {
  // Auto-detect platform and use appropriate URL
  // Android emulator uses 10.0.2.2 to access host machine
  // Web and other platforms use localhost
  static String get baseUrl {
    // Allow overriding at build/runtime via --dart-define=API_BASE_URL
    const _envBase = String.fromEnvironment('API_BASE_URL', defaultValue: '');
    if (_envBase.isNotEmpty) return _envBase;

    // Web builds run in browser — use localhost
    if (kIsWeb) return 'http://localhost:8000';

    // Native platforms: if Android emulator, use 10.0.2.2 to reach host
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000';
    }

    // Fallback: localhost
    return 'http://localhost:8000';
  }
}
