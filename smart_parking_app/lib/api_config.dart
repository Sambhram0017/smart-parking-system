import 'package:flutter/foundation.dart';

class ApiConfig {
  /// Live 24/7 Render Cloud Backend API
  /// Replace with your actual Render service URL after deploying (e.g., https://smart-parking-backend.onrender.com)
  static const String customCloudUrl = "https://smart-parking-backend.onrender.com";

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
