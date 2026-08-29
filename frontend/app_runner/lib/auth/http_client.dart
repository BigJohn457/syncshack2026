import 'package:http/http.dart' as http;

import 'http_client_stub.dart'
    if (dart.library.html) 'http_client_web.dart'
    as implementation;

final http.Client _sharedClient = implementation.createHttpClient();

http.Client createHttpClient() => _sharedClient;
