class ApiConfig {
  const ApiConfig._();

  static const String baseUrl = 'https://heybe.shahfitri.my';

  static Uri uri(String path) {
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$baseUrl$normalizedPath');
  }
}
