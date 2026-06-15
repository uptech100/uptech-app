import 'dart:io';
import 'package:flutter/foundation.dart';

class ApiConstants {
  /// The base URL of your API server.
  /// Change this to your production server URL when deploying.
  /// Example: 'https://api.uptech.com/api'
  // TODO: CHANGE THIS TO YOUR ACTUAL PRODUCTION DOMAIN BEFORE HOSTING!
  // Example: 'https://api.uptech.com/api' or 'http://192.168.1.100:3000/api'
  static const String PRODUCTION_API_URL = 'https://your-production-server.com/api';

  // Set this to true before generating the final APK/Web build
  static const bool isProduction = false;

  static String get baseUrl {
    if (isProduction) {
      return PRODUCTION_API_URL;
    }

    // Development URLs
    if (kIsWeb) {
      return 'http://localhost:3000/api';
    }
    // Android emulator
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:3000/api';
    }
    // iOS simulator
    if (Platform.isIOS) {
      return 'http://localhost:3000/api';
    }
    // Fallback for Windows/Mac/Linux desktop apps
    return 'http://localhost:3000/api';
  }
}
