import 'dart:convert';

import 'package:http/http.dart' as http;

import '../api_config.dart';
import 'http_client.dart';

class AuthException implements Exception {
  const AuthException(this.message);

  final String message;

  @override
  String toString() => message;
}

class AuthApi {
  AuthApi({http.Client? client}) : _client = client ?? createHttpClient();

  final http.Client _client;

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) {
    return _post('/api/auth/post/login', {
      'email': email.trim(),
      'password': password,
    });
  }

  Future<Map<String, dynamic>> signUp({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String phoneNumber,
    required String idPhoto,
    required String facePhoto,
  }) {
    return _post('/api/auth/post/signup', {
      'first_name': firstName.trim(),
      'last_name': lastName.trim(),
      'email': email.trim(),
      'password': password,
      'phone_number': phoneNumber.trim(),
      'id_photo': idPhoto.trim(),
      'face_photo': facePhoto.trim(),
    });
  }

  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> body,
  ) async {
    http.Response response;
    try {
      response = await _client.post(
        ApiConfig.uri(path),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
    } on Exception {
      throw const AuthException(
        'Could not connect to Hey. Check your internet connection and try again.',
      );
    }

    Map<String, dynamic> payload = const {};
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) payload = decoded;
    } on FormatException {
      // The status-based fallback below is clearer than exposing malformed HTML.
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final error = payload['error'];
      throw AuthException(
        error is String && error.isNotEmpty
            ? error
            : 'Request failed (${response.statusCode}). Please try again.',
      );
    }
    return payload;
  }
}
