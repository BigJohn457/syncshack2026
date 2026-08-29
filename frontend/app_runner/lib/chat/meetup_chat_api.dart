import 'dart:convert';

import 'package:http/http.dart' as http;

import '../api_config.dart';
import '../auth/auth_api.dart';
import '../auth/http_client.dart';

class MeetupChatMessage {
  const MeetupChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.senderIsRevealed,
    required this.message,
    required this.createdAt,
    this.senderImageUrl,
  });

  final String id;
  final String senderId;
  final String senderName;
  final bool senderIsRevealed;
  final String? senderImageUrl;
  final String message;
  final DateTime? createdAt;

  factory MeetupChatMessage.fromJson(Map<String, dynamic> json) {
    final sender = json['sender'];
    final senderData = sender is Map<String, dynamic>
        ? sender
        : const <String, dynamic>{};
    final imageUrl = senderData['img_url']?.toString().trim();
    final isRevealed =
        senderData['is_reveal'] == true || senderData['is_reveal'] == 1;
    final realName = senderData['real_name']?.toString().trim() ?? '';
    final anonymousName = senderData['anonymous_name']?.toString().trim() ?? '';
    return MeetupChatMessage(
      id: json['id']?.toString() ?? '',
      senderId: json['sender_id']?.toString() ?? '',
      senderName: isRevealed && realName.isNotEmpty
          ? realName
          : (anonymousName.isEmpty ? 'Anonymous member' : anonymousName),
      senderIsRevealed: isRevealed,
      senderImageUrl: imageUrl == null || imageUrl.isEmpty ? null : imageUrl,
      message: json['message']?.toString() ?? '',
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
    );
  }
}

class MeetupChatApi {
  MeetupChatApi({http.Client? client}) : _client = client ?? createHttpClient();

  final http.Client _client;

  Future<List<MeetupChatMessage>> fetchMessages(String meetupId) async {
    final uri = ApiConfig.uri(
      '/api/meetup-chat/get/all-messages',
    ).replace(queryParameters: {'meetup_id': meetupId});
    final payload = await _request(() => _client.get(uri));
    final data = payload['data'];
    if (data is! Map<String, dynamic>) return const [];
    final messages = data['messages'];
    if (messages is! List) return const [];
    return messages
        .whereType<Map<String, dynamic>>()
        .map(MeetupChatMessage.fromJson)
        .toList();
  }

  Future<MeetupChatMessage> sendMessage({
    required String meetupId,
    required String message,
  }) async {
    final payload = await _request(
      () => _client.post(
        ApiConfig.uri('/api/meetup-chat/post/send-message'),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({'meetup_id': meetupId, 'message': message}),
      ),
    );
    final data = payload['data'];
    final rawMessage = data is Map<String, dynamic> ? data['message'] : null;
    if (rawMessage is! Map<String, dynamic>) {
      throw const AuthException('The server returned an invalid message.');
    }
    return MeetupChatMessage.fromJson(rawMessage);
  }

  Future<Map<String, dynamic>> _request(
    Future<http.Response> Function() request,
  ) async {
    http.Response response;
    try {
      response = await request();
    } on Exception {
      throw const AuthException(
        'Could not connect to chat. Check your internet connection.',
      );
    }

    Map<String, dynamic> payload;
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) throw const FormatException();
      payload = decoded;
    } on FormatException {
      throw const AuthException('The server returned an invalid response.');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AuthException(
        payload['error']?.toString() ??
            'Chat request failed (${response.statusCode}).',
      );
    }
    return payload;
  }
}
