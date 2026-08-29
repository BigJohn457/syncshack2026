import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../api_config.dart';
import '../auth/auth_api.dart';
import '../auth/http_client.dart';

class ImageUploadApi {
  ImageUploadApi({http.Client? client})
    : _client = client ?? createHttpClient();
  final http.Client _client;

  Future<String> upload(XFile picture) async {
    try {
      final request =
          http.MultipartRequest(
              'POST',
              ApiConfig.uri('/api/upload/post/picture'),
            )
            ..files.add(
              http.MultipartFile.fromBytes(
                'picture',
                await picture.readAsBytes(),
                filename: picture.name.trim().isEmpty
                    ? 'upload.jpg'
                    : picture.name,
              ),
            );
      final streamed = await _client.send(request);
      final response = await http.Response.fromStream(streamed);
      final decoded = jsonDecode(response.body);
      final payload = decoded is Map<String, dynamic>
          ? decoded
          : const <String, dynamic>{};
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw AuthException(
          payload['error']?.toString() ??
              'Image upload failed (${response.statusCode}).',
        );
      }
      final data = payload['data'];
      final url = data is Map<String, dynamic> ? data['url']?.toString() : null;
      if (url == null || url.isEmpty) {
        throw const AuthException('The server returned an invalid image URL.');
      }
      return url;
    } on AuthException {
      rethrow;
    } on Exception {
      throw const AuthException(
        'Could not upload the image. Check your internet connection.',
      );
    }
  }
}
