import 'package:flutter/material.dart';
import 'auth/auth_api.dart';
import 'auth/auth_session.dart';
import 'meetups/meetup_api.dart';
import 'ratings/ratings_api.dart';

// "hey!" brand palette
const _kPurple = Color(0xFF6C3EE8);
const _kPurpleDark = Color(0xFF241B3A);
const _kCream = Color(0xFFFAF8F5);
const _kCardBg = Colors.white;

class MemberRating {
  final String userId;
  final String name;
  bool isChecked;
  int rating; // 0 to 5

  MemberRating({
    required this.userId,
    required this.name,
    this.isChecked = true,
    this.rating = 0,
  });
}

class RatePage extends StatefulWidget {
  final String meetupType;
  final String meetupId;
  final List<RateableMember> members;

  const RatePage({
    super.key,
    this.meetupType = 'meetup',
    this.meetupId = '',
    this.members = const [],
  });

  @override
  State<RatePage> createState() => _RatePageState();
}

class RateableMember {
  const RateableMember({required this.userId, required this.name});

  final String userId;
  final String name;
}

class _RatePageState extends State<RatePage> {
  late List<MemberRating> _members;
  final RatingsApi _ratingsApi = RatingsApi();
  final MeetupApi _meetupApi = MeetupApi();
  bool _submitting = false;
  bool _loadingMembers = true;
  String? _membersError;

  @override
  void initState() {
    super.initState();
    _members = widget.members
        .map(
          (member) => MemberRating(
            userId: member.userId,
            name: member.name,
            isChecked: false,
          ),
        )
        .toList();
    _loadParticipants();
  }

  Future<void> _loadParticipants() async {
    final meetupId = widget.meetupId.trim();
    if (meetupId.isEmpty) {
      setState(() {
        _loadingMembers = false;
        _membersError = 'This rating screen is missing its meetup ID.';
      });
      return;
    }
    setState(() {
      _loadingMembers = true;
      _membersError = null;
    });
    try {
      final participants = await _meetupApi.participants(meetupId);
      final currentUserId = AuthSession.currentUserId;
      final rateable = participants
          .where(
            (participant) =>
                participant.userId != currentUserId && participant.isActive,
          )
          .toList();
      final profiles = await Future.wait(
        rateable.map(
          (participant) => _meetupApi.anonymousProfile(participant.userId),
        ),
      );
      if (!mounted) return;
      setState(() {
        _members = List.generate(
          rateable.length,
          (index) => MemberRating(
            userId: rateable[index].userId,
            name: profiles[index].name,
            isChecked: false,
          ),
        );
      });
    } on AuthException catch (error) {
      if (mounted) setState(() => _membersError = error.message);
    } finally {
      if (mounted) setState(() => _loadingMembers = false);
    }
  }

  void _setRating(int memberIndex, int starIndex) {
    setState(() {
      if (_members[memberIndex].rating == starIndex) {
        _members[memberIndex].rating = 0; // Deselect if tapped again
        _members[memberIndex].isChecked = false;
      } else {
        _members[memberIndex].rating = starIndex;
        _members[memberIndex].isChecked = true;
      }
    });
  }

  void _toggleCheckbox(int memberIndex) {
    setState(() {
      _members[memberIndex].isChecked = !_members[memberIndex].isChecked;
    });
  }

  Future<void> _submitRatings() async {
    if (_submitting) return;
    if (widget.meetupId.trim().isEmpty) {
      _showError('This rating screen is missing its meetup ID.');
      return;
    }
    final selected = _members
        .where((member) => member.isChecked && member.rating > 0)
        .toList();
    if (selected.isEmpty) {
      _showError('Select at least one person and choose a rating.');
      return;
    }
    if (selected.any((member) => member.userId.trim().isEmpty)) {
      _showError('A selected participant is missing their user ID.');
      return;
    }

    setState(() => _submitting = true);
    final failures = <String>[];
    for (final member in selected) {
      try {
        await _ratingsApi.submit(
          meetupId: widget.meetupId.trim(),
          toUserId: member.userId.trim(),
          rating: member.rating,
        );
        member.isChecked = false;
        member.rating = 0;
      } on AuthException catch (error) {
        failures.add('${member.name}: ${error.message}');
      }
    }
    if (!mounted) return;
    if (failures.isNotEmpty) {
      setState(() => _submitting = false);
      _showError(failures.join('\n'));
      return;
    }

    try {
      await _meetupApi.finishParticipation(widget.meetupId.trim());
    } on AuthException catch (error) {
      if (mounted) {
        setState(() => _submitting = false);
        _showError(error.message);
      }
      return;
    }
    if (!mounted) return;

    Navigator.of(context).popUntil((route) => route.isFirst);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.star_rounded, color: Colors.amber, size: 22),
            SizedBox(width: 8),
            Text(
              'Ratings submitted! Thanks for being part of the community ✨',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF6C3EE8),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  Future<void> _skipRatings() async {
    if (_submitting) return;
    if (widget.meetupId.trim().isEmpty) {
      _showError('This rating screen is missing its meetup ID.');
      return;
    }
    setState(() => _submitting = true);
    try {
      await _meetupApi.finishParticipation(widget.meetupId.trim());
    } on AuthException catch (error) {
      if (mounted) _showError(error.message);
      return;
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
    if (!mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final topPadding = mediaQuery.padding.top;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: _kCream,
        body: Stack(
          children: [
            // Ambient bottom lavender wave gradient
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 200,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_kCream, Color(0xFFEDE7FA)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),

            // Floating Decorative Sparkles
            Positioned(
              top: topPadding + 65,
              left: 20,
              child: const Text(
                '✦',
                style: TextStyle(color: Color(0xFFC7B3FD), fontSize: 14),
              ),
            ),
            Positioned(
              top: topPadding + 130,
              right: 30,
              child: const Text(
                '✦',
                style: TextStyle(color: Color(0xFFC7B3FD), fontSize: 16),
              ),
            ),
            Positioned(
              bottom: 60,
              left: 32,
              child: const Text(
                '✦',
                style: TextStyle(color: Color(0xFFC7B3FD), fontSize: 14),
              ),
            ),
            Positioned(
              bottom: 80,
              right: 40,
              child: const Text(
                '✦',
                style: TextStyle(color: Color(0xFFC7B3FD), fontSize: 16),
              ),
            ),

            SafeArea(
              child: Column(
                children: [
                  // -------------------------------------------------------------
                  // TOP BAR: Round Back Button (Left), User Avatar (Right)
                  // -------------------------------------------------------------
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // User Avatar on Right
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF5A3825).withOpacity(0.15),
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.person,
                            color: _kPurple,
                            size: 28,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // -------------------------------------------------------------
                  // TITLE & SUBTITLE
                  // -------------------------------------------------------------
                  const Text(
                    'Rate the Meetup!',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: _kPurpleDark,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'How was your ${widget.meetupType}?',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF7E7993),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // -------------------------------------------------------------
                  // RATING CARDS LIST
                  // -------------------------------------------------------------
                  Expanded(
                    child: _loadingMembers
                        ? const Center(child: CircularProgressIndicator())
                        : _membersError != null
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _membersError!,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Color(0xFF7E7993),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  TextButton(
                                    onPressed: _loadParticipants,
                                    child: const Text('Try again'),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : _members.isEmpty
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(32),
                              child: Text(
                                'No participants are available to rate.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Color(0xFF7E7993)),
                              ),
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            itemCount: _members.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 16),
                            itemBuilder: (context, index) {
                              final member = _members[index];
                              return _buildRatingCard(index, member);
                            },
                          ),
                  ),

                  // -------------------------------------------------------------
                  // BOTTOM SUBMIT BUTTON
                  // -------------------------------------------------------------
                  Padding(
                    padding: EdgeInsets.only(
                      left: 24,
                      right: 24,
                      top: 10,
                      bottom: mediaQuery.padding.bottom > 0
                          ? mediaQuery.padding.bottom + 8
                          : 20,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          onTap: _submitting || _loadingMembers
                              ? null
                              : _submitRatings,
                          child: Container(
                            height: 56,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF6C3EE8), Color(0xFF8E45FF)],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              borderRadius: BorderRadius.circular(28),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFF6C3EE8,
                                  ).withOpacity(0.4),
                                  blurRadius: 16,
                                  spreadRadius: 1,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (_submitting)
                                  const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                else
                                  const Icon(
                                    Icons.check_circle_outline_rounded,
                                    color: Colors.white,
                                    size: 22,
                                  ),
                                const SizedBox(width: 8),
                                Text(
                                  _submitting
                                      ? 'Submitting...'
                                      : 'Submit Ratings ✨',
                                  style: const TextStyle(
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
                        const SizedBox(height: 6),
                        TextButton(
                          onPressed: _submitting ? null : _skipRatings,
                          child: const Text(
                            'Skip for now',
                            style: TextStyle(
                              color: _kPurple,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
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
      ),
    );
  }

  // -------------------------------------------------------------
  // RATING CARD WITH CHECKBOX & 3 INTERACTIVE STARS
  // -------------------------------------------------------------
  Widget _buildRatingCard(int memberIndex, MemberRating member) {
    return Container(
      height: 84,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Checkbox (Interactive)
          GestureDetector(
            onTap: () => _toggleCheckbox(memberIndex),
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: member.isChecked ? _kPurple : Colors.transparent,
                borderRadius: BorderRadius.circular(7),
                border: Border.all(
                  color: member.isChecked
                      ? _kPurple
                      : const Color(0xFF7C4DFF).withOpacity(0.5),
                  width: 2,
                ),
              ),
              child: member.isChecked
                  ? const Icon(Icons.check, color: Colors.white, size: 16)
                  : null,
            ),
          ),
          const SizedBox(width: 16),

          // Member Name
          Expanded(
            child: Text(
              member.name,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: _kPurpleDark,
                letterSpacing: -0.3,
              ),
            ),
          ),

          // 5-star rating required by the API.
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(5, (starIdx) {
              final starNumber = starIdx + 1;
              final isFilled = member.rating >= starNumber;

              return Padding(
                padding: const EdgeInsets.only(left: 4),
                child: GestureDetector(
                  onTap: () => _setRating(memberIndex, starNumber),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isFilled ? _kPurple : const Color(0xFFF6F3FD),
                      border: Border.all(
                        color: isFilled
                            ? _kPurple
                            : const Color(0xFF7C4DFF).withOpacity(0.25),
                        width: 1.5,
                      ),
                      boxShadow: isFilled
                          ? [
                              BoxShadow(
                                color: _kPurple.withOpacity(0.35),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ]
                          : [],
                    ),
                    child: Center(
                      child: Icon(
                        isFilled
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        color: isFilled
                            ? Colors.white
                            : const Color(0xFF241B3A),
                        size: 18,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
