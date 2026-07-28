import 'package:flutter/foundation.dart';

class ApiConfig {
  /// Set your deployed cloud backend URL here (e.g. "https://smart-parking-backend.onrender.com")
  /// Leave empty to automatically fallback to localhost (Web) / 10.0.2.2 (Android).
  static const String customCloudUrl = "";

  static String get baseUrl {
    if (customCloudUrl.isNotEmpty) {
      return customCloudUrl;
    }
    if (kIsWeb) {
      return "http://localhost:3000";
    }
    return "http://10.0.2.2:3000";
  }
}
