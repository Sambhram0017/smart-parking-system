import 'package:flutter/foundation.dart';

class ApiConfig {
  /// Live 24/7 Railway Cloud Backend API
  static const String customCloudUrl = "https://smart-parking-system-production-884b.up.railway.app";

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
