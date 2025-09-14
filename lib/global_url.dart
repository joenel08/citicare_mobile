import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String apiHost = '192.168.100.4';
const int apiPort = 80;
const String apiBasePath = 'citicare';

/// Builds a complete API URI with optional query parameters
Uri buildUri(String endpoint, [Map<String, dynamic>? queryParams]) {
  return Uri(
    scheme: 'http',
    host: apiHost,
    port: apiPort,
    path: '$apiBasePath/$endpoint',
    queryParameters:
        queryParams?.map((key, value) => MapEntry(key, value.toString())),
  );
}

/// Quick function if you just want to append an endpoint without query params
Uri url(String endpoint) {
  return buildUri(endpoint);
}

/// Example: Saving and getting a userId with SharedPreferences
// Future<void> saveUserId(int userId) async {
//   final prefs = await SharedPreferences.getInstance();
//   await prefs.setInt('userId', userId);
// }

// Future<int?> getUserId() async {
//   final prefs = await SharedPreferences.getInstance();
//   return prefs.getInt('userId');
// }
