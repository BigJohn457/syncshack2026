import 'dart:convert';
import 'dart:typed_data';

import 'package:app_runner/uploads/image_upload_api.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:image_picker/image_picker.dart';

void main() {
  test('uploads a selected image and returns its public URL', () async {
    late http.Request captured;
    final api = ImageUploadApi(
      client: MockClient((request) async {
        captured = request;
        return http.Response(
          jsonEncode({
            'success': true,
            'data': {'url': 'https://cdn.example.com/photo.jpg'},
          }),
          201,
        );
      }),
    );

    final url = await api.upload(
      XFile.fromData(
        Uint8List.fromList([1, 2, 3]),
        name: 'photo.jpg',
        mimeType: 'image/jpeg',
      ),
    );

    expect(captured.method, 'POST');
    expect(captured.url.path, '/api/upload/post/picture');
    expect(
      captured.headers['content-type'],
      startsWith('multipart/form-data;'),
    );
    expect(captured.body, contains('name="picture"'));
    expect(captured.body, contains('filename="upload.jpg"'));
    expect(url, 'https://cdn.example.com/photo.jpg');
  });
}
