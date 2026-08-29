import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'auth/auth_api.dart';
import 'auth/auth_session.dart';
import 'chat/meetup_chat_api.dart';
import 'gp_info.dart';
import 'meetups/meetup_api.dart';
import 'uploads/image_upload_api.dart';

class ChatPage extends StatefulWidget {
  final String matchName;
  final String matchAvatar;
  final String activity;
  final String place;
  final String meetupId;

  const ChatPage({
    super.key,
    this.matchName = '',
    this.matchAvatar = '',
    this.activity = '',
    this.place = '',
    this.meetupId = '',
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final MeetupChatApi _chatApi = MeetupChatApi();
  final MeetupApi _meetupApi = MeetupApi();
  final ImageUploadApi _imageUploadApi = ImageUploadApi();
  List<ChatMessage> _messages = const [];
  Timer? _refreshTimer;
  bool _loading = true;
  bool _sending = false;
  bool _refreshing = false;
  bool _revealing = false;
  bool _ownProfileRevealed = false;
  Set<String> _revealedUserIds = const {};
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.meetupId.trim().isEmpty) {
      _loading = false;
      _error = 'This chat is missing its meetup ID.';
    } else {
      _loadMessages();
      _refreshTimer = Timer.periodic(
        const Duration(seconds: 5),
        (_) => _loadMessages(silent: true),
      );
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadMessages({bool silent = false}) async {
    if (_refreshing || widget.meetupId.trim().isEmpty) return;
    _refreshing = true;
    if (!silent && mounted) setState(() => _loading = true);
    try {
      final results = await Future.wait<Object>([
        _chatApi.fetchMessages(widget.meetupId.trim()),
        _meetupApi.participants(widget.meetupId.trim()),
      ]);
      final messages = results[0] as List<MeetupChatMessage>;
      final participants = results[1] as List<MeetupParticipant>;
      if (!mounted) return;
      setState(() {
        _revealedUserIds = participants
            .where((participant) => participant.isReveal)
            .map((participant) => participant.userId)
            .toSet();
        final currentUserId = AuthSession.currentUserId;
        _ownProfileRevealed =
            currentUserId != null && _revealedUserIds.contains(currentUserId);
        _messages = messages.map(_toChatMessage).toList();
        _error = null;
      });
      _scrollToBottom();
    } on AuthException catch (error) {
      if (mounted && !silent) setState(() => _error = error.message);
    } finally {
      _refreshing = false;
      if (mounted && !silent) setState(() => _loading = false);
    }
  }

  ChatMessage _toChatMessage(MeetupChatMessage message) {
    final isMe =
        message.senderId.isNotEmpty &&
        message.senderId == AuthSession.currentUserId;
    return ChatMessage(
      id: message.id,
      sender: isMe ? 'You (Anonymous)' : message.senderName,
      text: message.message,
      time: _formatTime(message.createdAt),
      isMe: isMe,
      avatarColor: _avatarColor(message.senderId),
      avatarEmoji: isMe ? '🕵️' : '👤',
      avatarUrl: _revealedUserIds.contains(message.senderId)
          ? message.senderImageUrl
          : null,
    );
  }

  String _formatTime(DateTime? value) {
    if (value == null) return '';
    final local = value.toLocal();
    final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
    return '$hour:${local.minute.toString().padLeft(2, '0')} '
        '${local.hour < 12 ? 'AM' : 'PM'}';
  }

  Color _avatarColor(String senderId) {
    const colors = [
      Color(0xFF6D3B29),
      Color(0xFFE5B869),
      Color(0xFF355C3E),
      Color(0xFF6C3EE8),
    ];
    return colors[senderId.hashCode.abs() % colors.length];
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _sending || widget.meetupId.trim().isEmpty) return;
    setState(() => _sending = true);
    _textController.clear();
    try {
      final sent = await _chatApi.sendMessage(
        meetupId: widget.meetupId.trim(),
        message: text,
      );
      if (!mounted) return;
      if (AuthSession.currentUserId == null && sent.senderId.isNotEmpty) {
        AuthSession.currentUserId = sent.senderId;
      }
      setState(() {
        if (!_messages.any((message) => message.id == sent.id)) {
          _messages = [..._messages, _toChatMessage(sent)];
        }
        _error = null;
      });
      _scrollToBottom();
    } on AuthException catch (error) {
      if (!mounted) return;
      _textController.text = text;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _revealProfile() async {
    if (_revealing || _ownProfileRevealed) return;
    setState(() => _revealing = true);
    try {
      await _meetupApi.revealProfile(widget.meetupId.trim());
      await _loadMessages(silent: true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Your profile is now revealed.')),
        );
      }
    } on AuthException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    } finally {
      if (mounted) setState(() => _revealing = false);
    }
  }

  Future<void> _shareLocation() async {
    Navigator.pop(context);
    try {
      final position = await Geolocator.getCurrentPosition();
      _textController.text =
          'https://www.openstreetmap.org/?mlat=${position.latitude}&mlon=${position.longitude}';
      await _sendMessage();
    } on Exception {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not access your location.')),
        );
      }
    }
  }

  Future<void> _sharePhoto() async {
    Navigator.pop(context);
    final picture = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 88,
      maxWidth: 1800,
    );
    if (picture == null) return;
    try {
      _textController.text = await _imageUploadApi.upload(picture);
      await _sendMessage();
    } on AuthException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    }
  }

  void _showPlusActionsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4.5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Share with the Group',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E1B2E),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  width: 42,
                  height: 42,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEFF1FE),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.location_on,
                    color: Color(0xFF6C3EE8),
                  ),
                ),
                title: const Text(
                  'Share Live Location 📍',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: const Text('Let others know where you are standing'),
                onTap: _shareLocation,
              ),
              ListTile(
                leading: Container(
                  width: 42,
                  height: 42,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEDE7FA),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.camera_alt, color: Color(0xFF6C3EE8)),
                ),
                title: const Text(
                  'Send Photo 📸',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: const Text('Snap a picture of the meeting spot'),
                onTap: _sharePhoto,
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final topPadding = mediaQuery.padding.top;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color(0xFFFAF8F5),
        body: Stack(
          children: [
            // Background Gradient & Subtle Top Aura
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 180,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFF2EDFC), Color(0xFFFAF8F5)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),

            // Floating Decorative Sparkles
            Positioned(
              top: topPadding + 42,
              right: 135,
              child: const Text(
                '✦',
                style: TextStyle(color: Color(0xFFBCA7FB), fontSize: 13),
              ),
            ),
            Positioned(
              top: topPadding + 58,
              left: 145,
              child: const Text(
                '✦',
                style: TextStyle(color: Color(0xFFBCA7FB), fontSize: 11),
              ),
            ),
            Positioned(
              top: topPadding + 140,
              right: 32,
              child: const Text(
                '✦',
                style: TextStyle(color: Color(0xFFC9B6FD), fontSize: 14),
              ),
            ),

            // Main Column: Top Bar + Messages + Input
            SafeArea(
              child: Column(
                children: [
                  // -------------------------------------------------------------
                  // TOP BAR: Arrow Back, "Matched!" checkmark badge, Group Info Pill
                  // -------------------------------------------------------------
                  Padding(
                    padding: const EdgeInsets.only(
                      left: 16,
                      right: 16,
                      top: 8,
                      bottom: 6,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Center Matched Badge & Title
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Circular Checkmark Badge
                              Text(
                                widget.activity,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 19,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF1E1B2E),
                                  letterSpacing: -0.2,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '🔒 Anonymous meetup • ${widget.place}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF7E7993),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 8),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _headerButton(
                              icon: Icons.people_alt_rounded,
                              label: 'Group',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => GpInfoPage(
                                      meetupId: widget.meetupId,
                                      meetupTitle: widget.activity,
                                      meetupSubtitle: widget.place,
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 6),
                            _headerButton(
                              icon: _ownProfileRevealed
                                  ? Icons.visibility
                                  : Icons.visibility_outlined,
                              label: _ownProfileRevealed
                                  ? 'Revealed'
                                  : _revealing
                                  ? 'Revealing'
                                  : 'Reveal',
                              onTap: _ownProfileRevealed || _revealing
                                  ? null
                                  : _revealProfile,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Anonymous Safety Banner
                  Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEDE7FA),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: const [
                        Icon(
                          Icons.shield_outlined,
                          color: Color(0xFF6C3EE8),
                          size: 14,
                        ),
                        SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Anonymous chat • Profiles stay hidden until revealed',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF6C3EE8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 4),

                  // -------------------------------------------------------------
                  // CHAT MESSAGES LIST
                  // -------------------------------------------------------------
                  Expanded(
                    child: _loading
                        ? const Center(child: CircularProgressIndicator())
                        : _error != null && _messages.isEmpty
                        ? _buildChatError()
                        : RefreshIndicator(
                            onRefresh: _loadMessages,
                            child: ListView.builder(
                              controller: _scrollController,
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              itemCount: _messages.isEmpty
                                  ? 1
                                  : _messages.length,
                              itemBuilder: (context, index) {
                                if (_messages.isEmpty) {
                                  return const Padding(
                                    padding: EdgeInsets.only(top: 80),
                                    child: Center(
                                      child: Text(
                                        'No messages yet. Say hello!',
                                        style: TextStyle(
                                          color: Color(0xFF7E7993),
                                        ),
                                      ),
                                    ),
                                  );
                                }
                                return _buildMessageItem(_messages[index]);
                              },
                            ),
                          ),
                  ),

                  // -------------------------------------------------------------
                  // BOTTOM INPUT BAR: + Button, TextField, Send ↑ Button
                  // -------------------------------------------------------------
                  Padding(
                    padding: EdgeInsets.only(
                      left: 16,
                      right: 16,
                      top: 6,
                      bottom: mediaQuery.padding.bottom > 0
                          ? mediaQuery.padding.bottom
                          : 14,
                    ),
                    child: Container(
                      height: 56,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          // Plus (+) Circular Purple Button
                          GestureDetector(
                            onTap: _showPlusActionsSheet,
                            child: Container(
                              width: 38,
                              height: 38,
                              decoration: const BoxDecoration(
                                color: Color(0xFF6C3EE8),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.add,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),

                          // Message Input
                          Expanded(
                            child: TextField(
                              controller: _textController,
                              enabled: widget.meetupId.trim().isNotEmpty,
                              onSubmitted: (_) => _sendMessage(),
                              style: const TextStyle(
                                fontSize: 14.5,
                                color: Color(0xFF1E1B2E),
                                fontWeight: FontWeight.w500,
                              ),
                              decoration: const InputDecoration(
                                hintText: 'Message anonymously...',
                                hintStyle: TextStyle(
                                  color: Color(0xFFA09DB1),
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w400,
                                ),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                              ),
                            ),
                          ),

                          // Send (↑) Circular Purple Button
                          GestureDetector(
                            onTap: _sending ? null : _sendMessage,
                            child: Container(
                              width: 38,
                              height: 38,
                              decoration: const BoxDecoration(
                                color: Color(0xFF6C3EE8),
                                shape: BoxShape.circle,
                              ),
                              child: _sending
                                  ? const Padding(
                                      padding: EdgeInsets.all(10),
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.arrow_upward_rounded,
                                      color: Colors.white,
                                      size: 21,
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _headerButton({
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
  }) {
    return SizedBox(
      width: 92,
      height: 34,
      child: FilledButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 14),
        label: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.fade,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
        ),
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          backgroundColor: const Color(0xFF6C3EE8),
        ),
      ),
    );
  }

  Widget _buildChatError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.chat_bubble_outline, color: Color(0xFF7E7993)),
            const SizedBox(height: 12),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF7E7993)),
            ),
            if (widget.meetupId.trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              TextButton(
                onPressed: _loadMessages,
                child: const Text('Try again'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // MESSAGE ROW ITEM: Left & Right Chat Bubbles
  // -------------------------------------------------------------
  Widget _buildMessageItem(ChatMessage msg) {
    if (msg.isMe) {
      // Outgoing Message (Me on the Right)
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Purple Message Bubble
                  Container(
                    constraints: const BoxConstraints(maxWidth: 240),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 13,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6236E7),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(22),
                        topRight: Radius.circular(22),
                        bottomLeft: Radius.circular(22),
                        bottomRight: Radius.circular(6),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6236E7).withOpacity(0.28),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Text(
                      msg.text,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w500,
                        height: 1.3,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Timestamp & Purple Double Checks
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        msg.time,
                        style: const TextStyle(
                          color: Color(0xFF9E9AB2),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.done_all_rounded,
                        color: Color(0xFF6C3EE8),
                        size: 15,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),

            // User Avatar
            _buildAvatar(msg.avatarColor, msg.avatarEmoji, msg.avatarUrl),
          ],
        ),
      );
    } else {
      // Incoming Message (Others on the Left)
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Member Avatar
            _buildAvatar(msg.avatarColor, msg.avatarEmoji, msg.avatarUrl),
            const SizedBox(width: 10),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Member Name + Sparkle
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          msg.sender,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF241B3A),
                          ),
                        ),
                      ),
                      const SizedBox(width: 3),
                      const Text(
                        '✦',
                        style: TextStyle(
                          color: Color(0xFF8B64F8),
                          fontSize: 10.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Light Off-White Speech Bubble
                  Container(
                    constraints: const BoxConstraints(maxWidth: 240),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 13,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F1F8),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(6),
                        topRight: Radius.circular(22),
                        bottomLeft: Radius.circular(22),
                        bottomRight: Radius.circular(22),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.025),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      msg.text,
                      style: const TextStyle(
                        color: Color(0xFF1E1B2E),
                        fontSize: 14.5,
                        fontWeight: FontWeight.w500,
                        height: 1.3,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Timestamp
                  Text(
                    msg.time,
                    style: const TextStyle(
                      color: Color(0xFF9E9AB2),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildAvatar(Color color, String emoji, String? imageUrl) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: color.withOpacity(0.18),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: imageUrl == null
          ? Center(child: Text(emoji, style: const TextStyle(fontSize: 22)))
          : Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Center(
                child: Text(emoji, style: const TextStyle(fontSize: 22)),
              ),
            ),
    );
  }
}

class ChatMessage {
  final String id;
  final String sender;
  final String text;
  final String time;
  final bool isMe;
  final Color avatarColor;
  final String avatarEmoji;
  final String? avatarUrl;

  const ChatMessage({
    required this.id,
    required this.sender,
    required this.text,
    required this.time,
    required this.isMe,
    required this.avatarColor,
    required this.avatarEmoji,
    this.avatarUrl,
  });
}
