import 'package:app_runner/api_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('uses the production backend for every API path', () {
    expect(ApiConfig.baseUrl, 'https://heybe.shahfitri.my');
    expect(
      ApiConfig.uri('/api/auth/post/login').toString(),
      'https://heybe.shahfitri.my/api/auth/post/login',
    );
    expect(
      ApiConfig.uri('api/auth/post/signup').toString(),
      'https://heybe.shahfitri.my/api/auth/post/signup',
    );
  });
}
