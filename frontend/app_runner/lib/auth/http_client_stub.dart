import 'package:http/http.dart' as http;

http.Client createHttpClient() => _SessionClient();

class _SessionClient extends http.BaseClient {
  final http.Client _inner = http.Client();
  String? _cookie;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final cookie = _cookie;
    if (cookie != null) request.headers['Cookie'] = cookie;
    final response = await _inner.send(request);
    final setCookie = response.headers['set-cookie'];
    if (setCookie != null && setCookie.isNotEmpty) {
      _cookie = setCookie.split(';').first;
    }
    return response;
  }

  @override
  void close() => _inner.close();
}
