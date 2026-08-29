import 'package:flutter/material.dart';

// "hey!" brand palette
const _kPurple = Color(0xFF6C3EE8);
const _kPurpleDark = Color(0xFF241B3A);
const _kCream = Color(0xFFFAF8F5);
const _kCardBg = Colors.white;

class MemberRating {
  final String name;
  bool isChecked;
  int rating; // 0 to 3

  MemberRating({
    required this.name,
    this.isChecked = true,
    this.rating = 0,
  });
}

class RatePage extends StatefulWidget {
  final String meetupType;

  const RatePage({
    super.key,
    this.meetupType = 'coffee meetup',
  });

  @override
  State<RatePage> createState() => _RatePageState();
}

class _RatePageState extends State<RatePage> {
  late List<MemberRating> _members;

  @override
  void initState() {
    super.initState();
    _members = [
      MemberRating(name: 'John', isChecked: false, rating: 1),
      MemberRating(name: 'Maya', isChecked: false, rating: 2),
      MemberRating(name: 'Ethan', isChecked: false, rating: 0),
    ];
  }

  void _setRating(int memberIndex, int starIndex) {
    setState(() {
      if (_members[memberIndex].rating == starIndex) {
        _members[memberIndex].rating = 0; // Deselect if tapped again
      } else {
        _members[memberIndex].rating = starIndex;
      }
    });
  }

  void _toggleCheckbox(int memberIndex) {
    setState(() {
      _members[memberIndex].isChecked = !_members[memberIndex].isChecked;
    });
  }

  void _submitRatings() {
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final topPadding = mediaQuery.padding.top;

    return Scaffold(
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
                  colors: [
                    _kCream,
                    Color(0xFFEDE7FA),
                  ],
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
            child: const Text('✦',
                style: TextStyle(color: Color(0xFFC7B3FD), fontSize: 14)),
          ),
          Positioned(
            top: topPadding + 130,
            right: 30,
            child: const Text('✦',
                style: TextStyle(color: Color(0xFFC7B3FD), fontSize: 16)),
          ),
          Positioned(
            bottom: 60,
            left: 32,
            child: const Text('✦',
                style: TextStyle(color: Color(0xFFC7B3FD), fontSize: 14)),
          ),
          Positioned(
            bottom: 80,
            right: 40,
            child: const Text('✦',
                style: TextStyle(color: Color(0xFFC7B3FD), fontSize: 16)),
          ),

          SafeArea(
            child: Column(
              children: [
                // -------------------------------------------------------------
                // TOP BAR: Round Back Button (Left), User Avatar (Right)
                // -------------------------------------------------------------
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Back Button (Round White Pill)
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.06),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.arrow_back,
                            color: _kPurpleDark,
                            size: 24,
                          ),
                        ),
                      ),

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
                        child: const Center(
                          child: Text(
                            '👩🏽',
                            style: TextStyle(fontSize: 26),
                          ),
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
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: _members.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
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
                  child: GestureDetector(
                    onTap: _submitRatings,
                    child: Container(
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF6C3EE8),
                            Color(0xFF8E45FF),
                          ],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF6C3EE8).withOpacity(0.4),
                            blurRadius: 16,
                            spreadRadius: 1,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.check_circle_outline_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Submit Ratings ✨',
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
                ),
              ],
            ),
          ),
        ],
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
                  ? const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 16,
                    )
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

          // 3 Interactive Star Rating Buttons
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(3, (starIdx) {
              final starNumber = starIdx + 1;
              final isFilled = member.rating >= starNumber;

              return Padding(
                padding: const EdgeInsets.only(left: 10),
                child: GestureDetector(
                  onTap: () => _setRating(memberIndex, starNumber),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isFilled
                          ? _kPurple
                          : const Color(0xFFF6F3FD),
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
                        size: 21,
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
