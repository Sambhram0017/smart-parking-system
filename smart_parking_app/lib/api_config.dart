import 'package:flutter/foundation.dart';

class ApiConfig {
  /// Returns appropriate base URL based on platform.
  /// Web uses `http://localhost:3000` (or `http://127.0.0.1:3000`).
  /// Android Emulator uses `http://10.0.2.2:3000`.
  static String get baseUrl {
    if (kIsWeb) {
      return "http://localhost:3000";
    }
    return "http://10.0.2.2:3000";
  }
}
