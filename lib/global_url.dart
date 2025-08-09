import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String baseUri = 'http://192.168.100.4/citicare/users/';

Uri url(String endpoint) {
  return Uri.parse('$baseUri$endpoint');
}

Uri buildUri(String endpoint, [Map<String, dynamic>? queryParams]) {
  return Uri(
    scheme: 'http',
    host: '192.168.100.4',
    port: 80,
    path: 'citicare/users/$endpoint',
    queryParameters:
        queryParams?.map((key, value) => MapEntry(key, value.toString())),
  );
}
