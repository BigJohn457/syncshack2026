import 'package:flutter/material.dart';
import 'rate.dart';
import 'home_page.dart';

// "hey!" brand palette & styling
const _kPurple = Color(0xFF6C3EE8);
const _kPurpleDark = Color(0xFF241B3A);
const _kCream = Color(0xFFFAF8F5);
const _kLavenderPill = Color(0xFFEDE7FA);
const _kAttendingCard = Color(0xFFEFF9F3);
const _kAttendingBorder = Color(0xFFD8F2E2);
const _kAttendingGreen = Color(0xFF2EAF6C);
const _kPendingCard = Color(0xFFFEF8E7);
const _kPendingBorder = Color(0xFFFCEEC8);
const _kPendingYellow = Color(0xFFE5A117);

enum AttendanceStatus { attending, pending }

class Participant {
  final String userId;
  final String name;
  final String avatarEmoji;
  final Color avatarBgColor;
  final AttendanceStatus status;

  const Participant({
    this.userId = '',
    required this.name,
    required this.avatarEmoji,
    required this.avatarBgColor,
    required this.status,
  });
}

class GpInfoPage extends StatelessWidget {
  final String meetupId;
  final String meetupTitle;
  final String meetupSubtitle;
  final List<Participant> participants;

  const GpInfoPage({
    super.key,
    this.meetupId = '',
    this.meetupTitle = 'GROUP INFO',
    this.meetupSubtitle = 'Coffee Meetup • Today at 3:30 PM',
    this.participants = const [
      Participant(
        name: 'Maya',
        avatarEmoji: '👩🏽',
        avatarBgColor: Color(0xFF6D3B29),
        status: AttendanceStatus.attending,
      ),
      Participant(
        name: 'Jasmine',
        avatarEmoji: '👱🏼‍♀️',
        avatarBgColor: Color(0xFFE5B869),
        status: AttendanceStatus.attending,
      ),
      Participant(
        name: 'Sophie',
        avatarEmoji: '👩🏼',
        avatarBgColor: Color(0xFF8B5E3C),
        status: AttendanceStatus.pending,
      ),
      Participant(
        name: 'Ethan',
        avatarEmoji: '👦🏽',
        avatarBgColor: Color(0xFF355C3E),
        status: AttendanceStatus.pending,
      ),
    ],
  });

  int get _attendingCount =>
      participants.where((p) => p.status == AttendanceStatus.attending).length;

  int get _pendingCount =>
      participants.where((p) => p.status == AttendanceStatus.pending).length;

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final topPadding = mediaQuery.padding.top;

    return Scaffold(
      backgroundColor: _kCream,
      body: Stack(
        children: [
          // Subtle top-left & bottom-right ambient gradient
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 160,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFF3EDFC), _kCream],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),

          // Floating Decorative Sparkles
          Positioned(
            top: topPadding + 62,
            right: 68,
            child: const Text(
              '✦',
              style: TextStyle(color: Color(0xFFC7B3FD), fontSize: 13),
            ),
          ),
          Positioned(
            top: topPadding + 155,
            left: 28,
            child: const Text(
              '✦',
              style: TextStyle(color: Color(0xFFBCA7FB), fontSize: 15),
            ),
          ),
          Positioned(
            top: topPadding + 168,
            left: 40,
            child: const Text(
              '✦',
              style: TextStyle(color: Color(0xFFBCA7FB), fontSize: 11),
            ),
          ),
          Positioned(
            top: topPadding + 195,
            right: 36,
            child: const Text('💫', style: TextStyle(fontSize: 16)),
          ),

          SafeArea(
            child: Column(
              children: [
                // -------------------------------------------------------------
                // TOP BAR: Left Back/Avatar, Center "hey! ✨", Right Group Icon
                // -------------------------------------------------------------
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Left User Avatar / Back Button
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF5A3825).withOpacity(0.18),
                            border: Border.all(
                              color: const Color(0xFF6C3EE8).withOpacity(0.3),
                              width: 2.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.06),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Text('👩🏽', style: TextStyle(fontSize: 24)),
                          ),
                        ),
                      ),

                      // Center Brand Logo: hey! ✨
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'hey!',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              color: _kPurple,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(width: 2),
                          Transform.translate(
                            offset: const Offset(0, -6),
                            child: const Text(
                              '✨',
                              style: TextStyle(fontSize: 15),
                            ),
                          ),
                        ],
                      ),

                      // Right Group Icon Pill Container
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: _kPurple,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: _kPurple.withOpacity(0.35),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.people_alt_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // -------------------------------------------------------------
                // HEADER TITLE & ATTENDANCE SUMMARY PILL
                // -------------------------------------------------------------
                Text(
                  meetupTitle,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: _kPurpleDark,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  meetupSubtitle,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF7E7993),
                  ),
                ),
                const SizedBox(height: 12),

                // Attendance Pill
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: _kLavenderPill,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.people_alt_rounded,
                        color: _kPurple,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '$_attendingCount attending • $_pendingCount pending',
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: _kPurple,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // -------------------------------------------------------------
                // PARTICIPANT CARDS LIST
                // -------------------------------------------------------------
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: participants.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 14),
                    itemBuilder: (context, index) {
                      final p = participants[index];
                      return _ParticipantCard(participant: p);
                    },
                  ),
                ),

                // -------------------------------------------------------------
                // BOTTOM BUTTONS: Green "Finished" -> rate.dart + Red "Cancel"
                // -------------------------------------------------------------
                Padding(
                  padding: EdgeInsets.only(
                    left: 20,
                    right: 20,
                    top: 6,
                    bottom: mediaQuery.padding.bottom > 0
                        ? mediaQuery.padding.bottom + 8
                        : 16,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 🟢 Green "Finished" Button -> Goes to rate.dart
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => RatePage(
                                meetupId: meetupId,
                                meetupType: 'coffee meetup',
                                members: participants
                                    .where(
                                      (participant) =>
                                          participant.status ==
                                          AttendanceStatus.attending,
                                    )
                                    .map(
                                      (participant) => RateableMember(
                                        userId: participant.userId,
                                        name: participant.name,
                                      ),
                                    )
                                    .toList(),
                              ),
                            ),
                          );
                        },
                        child: Container(
                          height: 54,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF27AE60), Color(0xFF2ECC71)],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF27AE60).withOpacity(0.4),
                                blurRadius: 16,
                                spreadRadius: 1,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.check_circle_rounded,
                                color: Colors.white,
                                size: 22,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Finished',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // 🔴 Red "Leave Meetup" Button -> Leaves directly to HomePage
                      GestureDetector(
                        onTap: () {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const HomePage(),
                            ),
                            (route) => false,
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Row(
                                children: [
                                  Icon(
                                    Icons.logout_rounded,
                                    color: Colors.white,
                                    size: 19,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'You left the meetup. Returned to home map.',
                                  ),
                                ],
                              ),
                              backgroundColor: const Color(0xFFE53935),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          );
                        },
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFDE8E8),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: const Color(0xFFEA5B5B).withOpacity(0.35),
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.logout_rounded,
                                color: Color(0xFFEA5B5B),
                                size: 19,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Leave Meetup',
                                style: TextStyle(
                                  color: Color(0xFFEA5B5B),
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w700,
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
        ],
      ),
    );
  }
}

// -------------------------------------------------------------
// PARTICIPANT CARD WIDGET
// -------------------------------------------------------------
class _ParticipantCard extends StatelessWidget {
  final Participant participant;

  const _ParticipantCard({required this.participant});

  @override
  Widget build(BuildContext context) {
    final isAttending = participant.status == AttendanceStatus.attending;
    final cardBgColor = isAttending ? _kAttendingCard : _kPendingCard;
    final cardBorderColor = isAttending ? _kAttendingBorder : _kPendingBorder;
    final badgeTextColor = isAttending ? _kAttendingGreen : _kPendingYellow;
    final badgeLabel = isAttending ? 'ATTENDING!' : 'PENDING...';
    final sparkleColor = isAttending
        ? const Color(0xFF8B64F8)
        : const Color(0xFFE5A117);

    return Container(
      height: 82,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: cardBorderColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.025),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background Watermark Outline on Right Side
          Positioned(
            right: 0,
            top: 6,
            bottom: 6,
            child: Opacity(
              opacity: 0.12,
              child: isAttending
                  ? const Icon(
                      Icons.check_circle_outline_rounded,
                      size: 70,
                      color: _kAttendingGreen,
                    )
                  : const Icon(
                      Icons.hourglass_empty_rounded,
                      size: 65,
                      color: _kPendingYellow,
                    ),
            ),
          ),

          // Foreground Content: Avatar + Name + Sparkles + Status Pill
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 3D Avatar Memoji Circle
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: participant.avatarBgColor.withOpacity(0.18),
                  border: Border.all(color: Colors.white, width: 2.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    participant.avatarEmoji,
                    style: const TextStyle(fontSize: 28),
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Name + Sparkles
              Expanded(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        participant.name,
                        style: const TextStyle(
                          fontSize: 17.5,
                          fontWeight: FontWeight.w800,
                          color: _kPurpleDark,
                          letterSpacing: -0.2,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '✦',
                      style: TextStyle(
                        color: sparkleColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '✦',
                      style: TextStyle(
                        color: sparkleColor.withOpacity(0.7),
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              // Status Pill (Elevated White Container)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  badgeLabel,
                  style: TextStyle(
                    color: badgeTextColor,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
