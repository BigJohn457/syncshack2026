import 'package:flutter/material.dart';
import 'gp_info.dart';

class ChatPage extends StatefulWidget {
  final String matchName;
  final String matchAvatar;
  final String activity;
  final String place;

  const ChatPage({
    super.key,
    this.matchName = 'Anonymous Meetup',
    this.matchAvatar = '',
    this.activity = 'Coffee Meetup',
    this.place = 'Single O / Surry Hills',
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  late List<ChatMessage> _messages;

  @override
  void initState() {
    super.initState();
    _messages = [
      ChatMessage(
        sender: 'Anonymous Koala',
        text: 'Hey! Are we still meeting at 3:30?',
        time: '2:45 PM',
        isMe: false,
        avatarColor: const Color(0xFF6D3B29),
        avatarEmoji: '🐨',
      ),
      ChatMessage(
        sender: 'You (Anonymous)',
        text: "Yep! I'm about 5 mins away ☕",
        time: '2:46 PM',
        isMe: true,
        avatarColor: const Color(0xFF5A3825),
        avatarEmoji: '🕵️',
      ),
      ChatMessage(
        sender: 'Anonymous Fox',
        text: 'Perfect, see you there!',
        time: '2:47 PM',
        isMe: false,
        avatarColor: const Color(0xFFE5B869),
        avatarEmoji: '🦊',
      ),
      ChatMessage(
        sender: 'You (Anonymous)',
        text: "I'm outside near the entrance 👋",
        time: '2:49 PM',
        isMe: true,
        avatarColor: const Color(0xFF5A3825),
        avatarEmoji: '🕵️',
      ),
      ChatMessage(
        sender: 'Anonymous Owl',
        text: 'On my way!',
        time: '2:50 PM',
        isMe: false,
        avatarColor: const Color(0xFF355C3E),
        avatarEmoji: '🦉',
      ),
    ];
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    final now = TimeOfDay.now();
    final hour = now.hourOfPeriod == 0 ? 12 : now.hourOfPeriod;
    final minute = now.minute.toString().padLeft(2, '0');
    final period = now.period == DayPeriod.am ? 'AM' : 'PM';
    final timeStr = '$hour:$minute $period';

    setState(() {
      _messages.add(
        ChatMessage(
          sender: 'You (Anonymous)',
          text: text,
          time: timeStr,
          isMe: true,
          avatarColor: const Color(0xFF5A3825),
          avatarEmoji: '🕵️',
        ),
      );
    });

    _textController.clear();

    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 80,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });

    // Simulated anonymous group reply
    Future.delayed(const Duration(milliseconds: 1400), () {
      if (mounted) {
        setState(() {
          _messages.add(
            ChatMessage(
              sender: 'Anonymous Koala',
              text: 'Just grabbed a table near the window! 🪟☕',
              time: timeStr,
              isMe: false,
              avatarColor: const Color(0xFF6D3B29),
              avatarEmoji: '🐨',
            ),
          );
        });

        Future.delayed(const Duration(milliseconds: 100), () {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent + 80,
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
            );
          }
        });
      }
    });
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
                  child: const Icon(Icons.location_on, color: Color(0xFF6C3EE8)),
                ),
                title: const Text('Share Live Location 📍',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Let others know where you are standing'),
                onTap: () {
                  Navigator.pop(context);
                  _textController.text = "📍 Sharing my live location: Outside main lobby";
                  _sendMessage();
                },
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
                title: const Text('Send Photo 📸',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Snap a picture of the meeting spot'),
                onTap: () {
                  Navigator.pop(context);
                  _textController.text = "📸 [Sent Photo: Outside cafe]";
                  _sendMessage();
                },
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

    return Scaffold(
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
                  colors: [
                    Color(0xFFF2EDFC),
                    Color(0xFFFAF8F5),
                  ],
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
            child: const Text('✦', style: TextStyle(color: Color(0xFFBCA7FB), fontSize: 13)),
          ),
          Positioned(
            top: topPadding + 58,
            left: 145,
            child: const Text('✦', style: TextStyle(color: Color(0xFFBCA7FB), fontSize: 11)),
          ),
          Positioned(
            top: topPadding + 140,
            right: 32,
            child: const Text('✦', style: TextStyle(color: Color(0xFFC9B6FD), fontSize: 14)),
          ),

          // Main Column: Top Bar + Messages + Input
          SafeArea(
            child: Column(
              children: [
                // -------------------------------------------------------------
                // TOP BAR: Arrow Back, "Matched!" checkmark badge, Group Info Pill
                // -------------------------------------------------------------
                Padding(
                  padding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Back Arrow
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 40,
                          height: 40,
                          alignment: Alignment.centerLeft,
                          child: const Icon(
                            Icons.arrow_back,
                            color: Color(0xFF1E1B2E),
                            size: 26,
                          ),
                        ),
                      ),

                      // Center Matched Badge & Title
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Circular Checkmark Badge
                            Container(
                              width: 44,
                              height: 44,
                              decoration: const BoxDecoration(
                                color: Color(0xFFEDE7FA),
                                shape: BoxShape.circle,
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.check_rounded,
                                  color: Color(0xFF6C3EE8),
                                  size: 24,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Matched!',
                              style: TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF1E1B2E),
                                letterSpacing: -0.2,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '🔒 Anonymous Meetup • Today 3:30 PM',
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF7E7993),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Right: "👥 Group Info" Pill Button -> Navigates to gp_info.dart
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const GpInfoPage(),
                            ),
                          );
                        },
                        child: Container(
                          height: 38,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6C3EE8),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF6C3EE8).withOpacity(0.35),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(
                                Icons.people_alt_rounded,
                                color: Colors.white,
                                size: 16,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'Group Info',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Anonymous Safety Banner
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDE7FA),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.shield_outlined, color: Color(0xFF6C3EE8), size: 14),
                      SizedBox(width: 6),
                      Text(
                        'Anonymous Chat • Real identities hidden until you meet',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF6C3EE8),
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
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      return _buildMessageItem(msg);
                    },
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
                              contentPadding: EdgeInsets.symmetric(vertical: 10),
                            ),
                          ),
                        ),

                        // Send (↑) Circular Purple Button
                        GestureDetector(
                          onTap: _sendMessage,
                          child: Container(
                            width: 38,
                            height: 38,
                            decoration: const BoxDecoration(
                              color: Color(0xFF6C3EE8),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Purple Message Bubble
                Container(
                  constraints: const BoxConstraints(maxWidth: 240),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
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
            const SizedBox(width: 10),

            // User Avatar
            _buildAvatar(msg.avatarColor, msg.avatarEmoji),
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
            _buildAvatar(msg.avatarColor, msg.avatarEmoji),
            const SizedBox(width: 10),

            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Member Name + Sparkle
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      msg.sender,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF241B3A),
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
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
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
          ],
        ),
      );
    }
  }

  Widget _buildAvatar(Color color, String emoji) {
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
      child: Center(
        child: Text(
          emoji,
          style: const TextStyle(fontSize: 22),
        ),
      ),
    );
  }
}

class ChatMessage {
  final String sender;
  final String text;
  final String time;
  final bool isMe;
  final Color avatarColor;
  final String avatarEmoji;

  const ChatMessage({
    required this.sender,
    required this.text,
    required this.time,
    required this.isMe,
    required this.avatarColor,
    required this.avatarEmoji,
  });
}

