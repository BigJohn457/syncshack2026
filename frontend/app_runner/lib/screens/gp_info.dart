import 'package:flutter/material.dart';
import 'chat.dart';
import 'rate.dart';

// "hey!" brand palette
const _kPurple = Color(0xFF7C4DFF);
const _kPurpleDark = Color(0xFF6C3CE0);
const _kCream = Color(0xFFFBF7F2);
const _kLavender = Color(0xFFEDE7FA);
const _kMintCard = Color(0xFFDFF5E8);
const _kMintText = Color(0xFF2F9E6B);
const _kYellowCard = Color(0xFFFCF0CE);
const _kYellowText = Color(0xFFB8860B);
const _kMutedRed = Color(0xFFE0736A);

enum AttendanceStatus { attending, pending }

class Participant {
  final String name;
  final String avatarUrl;
  final AttendanceStatus status;

  const Participant({
    required this.name,
    required this.avatarUrl,
    required this.status,
  });
}

class GpInfoPage extends StatelessWidget {
  final String meetupTitle;
  final String meetupSubtitle;
  final String currentUserAvatarUrl;
  final List<Participant> participants;

  const GpInfoPage({
    super.key,
    this.meetupTitle = 'GROUP INFO',
    this.meetupSubtitle = 'Coffee Meetup · Today at 3:30 PM',
    this.currentUserAvatarUrl = '',
    this.participants = const [
      Participant(
        name: 'Maya',
        avatarUrl: '',
        status: AttendanceStatus.attending,
      ),
      Participant(
        name: 'Leo',
        avatarUrl: '',
        status: AttendanceStatus.attending,
      ),
      Participant(
        name: 'Priya',
        avatarUrl: '',
        status: AttendanceStatus.pending,
      ),
      Participant(
        name: 'Sam',
        avatarUrl: '',
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
    return Scaffold(
      backgroundColor: _kCream,
      body: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [_kLavender, _kCream],
              stops: [0.0, 0.35],
            ),
          ),
          child: Column(
            children: [
              _TopBar(currentUserAvatarUrl: currentUserAvatarUrl),
              const SizedBox(height: 12),
              Text(
                meetupTitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  color: _kPurpleDark,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                meetupSubtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: _kPurpleDark.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '$_attendingCount attending · $_pendingCount pending',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _kPurpleDark.withOpacity(0.45),
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: participants.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    return _ParticipantCard(participant: participants[index]);
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChatPage(meetupTitle: meetupTitle),
                            ),
                          );
                        },
                        icon: const Icon(Icons.chat_bubble_outline_rounded),
                        label: const Text('Message Group'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _kPurple,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => RatePage(meetupTitle: meetupTitle),
                            ),
                          );
                        },
                        icon: const Icon(Icons.star_outline_rounded),
                        label: const Text('Rate This Meetup'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _kPurpleDark,
                          side: const BorderSide(color: _kPurpleDark),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _CancelMeetupButton(
                      onPressed: () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Cancel this meetup?'),
                            content: const Text(
                              'The other participants will be notified that you\'re no longer joining.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text('Keep it'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                child: const Text(
                                  'Yes, cancel',
                                  style: TextStyle(color: _kMutedRed),
                                ),
                              ),
                            ],
                          ),
                        );
                        if (confirmed == true && context.mounted) {
                          Navigator.pop(context, true);
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final String currentUserAvatarUrl;

  const _TopBar({required this.currentUserAvatarUrl});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _Avatar(imageUrl: currentUserAvatarUrl, radius: 22),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _kPurple,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: _kPurple.withOpacity(0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
          ),
        ],
      ),
    );
  }
}

class _ParticipantCard extends StatelessWidget {
  final Participant participant;

  const _ParticipantCard({required this.participant});

  @override
  Widget build(BuildContext context) {
    final isAttending = participant.status == AttendanceStatus.attending;
    final cardColor = isAttending ? _kMintCard : _kYellowCard;
    final textColor = isAttending ? _kMintText : _kYellowText;
    final label = isAttending ? 'ATTENDING!' : 'PENDING…';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: _kPurpleDark.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          _Avatar(imageUrl: participant.avatarUrl, radius: 26),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              participant.name,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Color(0xFF3A2E5C),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.3,
                color: textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String imageUrl;
  final double radius;

  const _Avatar({required this.imageUrl, required this.radius});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: _kLavender,
      backgroundImage: imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
      child: imageUrl.isEmpty
          ? Icon(Icons.person, color: _kPurple, size: radius)
          : null,
    );
  }
}

class _CancelMeetupButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _CancelMeetupButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: _kMutedRed,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        child: const Text(
          'Cancel Meetup',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
