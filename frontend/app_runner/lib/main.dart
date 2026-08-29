import 'package:flutter/material.dart';
import 'datetime.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Meetup App',
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'SF Pro Display',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6C3EE8),
          primary: const Color(0xFF6C3EE8),
        ),
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedCardIndex = 0;
  String? _selectedPinId;

  // Match Cards Data
  final List<Map<String, dynamic>> _matchCards = [
    {
      'title': 'Grab coffee ☕',
      'subtitle': 'Looking for a coffee buddy nearby!',
      'time': '15 mins ago',
      'distance': '0.4 km away',
      'emoji': '☕',
      'person': 'Alex Rivera',
      'place': 'Blue Bottle Coffee',
      'bio': 'Taking a break from laptop work, would love a quick coffee and chat!'
    },
    {
      'title': 'Afternoon Walk 🚶',
      'subtitle': 'Going for a brisk walk in the park!',
      'time': '8 mins ago',
      'distance': '0.2 km away',
      'emoji': '🚶',
      'person': 'Jordan Lee',
      'place': 'Harbor Park Trail',
      'bio': 'Enjoying the sunny weather. Down for a 20-minute walk around the bay.'
    },
  ];

  // 5 Map Pins matching the exact positions & texts in the screenshot
  late List<MapPinData> _pins;

  @override
  void initState() {
    super.initState();
    _pins = [
      const MapPinData(
        id: 'pin_1',
        title: 'Wants to grab\ncoffee! ☕',
        time: '15 mins ago',
        relativeX: 0.48,
        relativeY: 0.16,
        category: 'Coffee',
        author: 'Elena R.',
        distance: '0.4 km away',
        description: 'Working at a cafe nearby, free for the next hour to grab an espresso!',
      ),
      const MapPinData(
        id: 'pin_2',
        title: 'Down for\na walk 🚶',
        time: '8 mins ago',
        relativeX: 0.26,
        relativeY: 0.43,
        category: 'Walk',
        author: 'Marcus K.',
        distance: '0.3 km away',
        description: 'Going for a walk along the waterfront promenade. Join in!',
      ),
      const MapPinData(
        id: 'pin_3',
        title: 'Brunch\nanyone? 🥐',
        time: '22 mins ago',
        relativeX: 0.70,
        relativeY: 0.49,
        category: 'Food',
        author: 'Sophie T.',
        distance: '0.8 km away',
        description: 'Heading to the French bakery on 4th street. Craving croissants & matcha!',
      ),
      const MapPinData(
        id: 'pin_4',
        title: 'Open to\nany plans! 🎉',
        time: '12 mins ago',
        relativeX: 0.31,
        relativeY: 0.72,
        category: 'Social',
        author: 'David L.',
        distance: '0.5 km away',
        description: 'Finished my tasks early today! Up for bouldering, board games, or boba.',
      ),
      const MapPinData(
        id: 'pin_5',
        title: "Let's explore\nthe city! 🌉",
        time: '5 mins ago',
        relativeX: 0.78,
        relativeY: 0.76,
        category: 'Explore',
        author: 'Chloe M.',
        distance: '0.9 km away',
        description: 'Visiting the city for the weekend! Looking for locals to check out the views.',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final topPadding = mediaQuery.padding.top;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4FD),
      body: Column(
        children: [
          // -------------------------------------------------------------
          // TOP SECTION (Header + Top Match Card + Pagination)
          // -------------------------------------------------------------
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFEFF1FE),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(32),
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6C3EE8).withOpacity(0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.only(
                top: topPadding > 0 ? topPadding + 6 : 24,
                left: 20,
                right: 20,
                bottom: 16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Row: Avatar & Notifications
                  _buildTopBar(),
                  const SizedBox(height: 18),

                  // Section Title: "Your top match"
                  _buildSectionHeader(),
                  const SizedBox(height: 14),

                  // White Top Match Card
                  _buildTopMatchCard(),
                  const SizedBox(height: 14),

                  // Pagination Dots
                  _buildPaginationDots(),
                ],
              ),
            ),
          ),

          // -------------------------------------------------------------
          // BOTTOM SECTION (Interactive Vector Map + Pins + FAB)
          // -------------------------------------------------------------
          Expanded(
            child: Stack(
              children: [
                // Stylized Vector Map Canvas
                Positioned.fill(
                  child: ClipRect(
                    child: CustomPaint(
                      painter: MapBackgroundPainter(),
                    ),
                  ),
                ),

                // Top-Left: "4 requests on the map" Dropdown Pill
                Positioned(
                  top: 14,
                  left: 16,
                  child: _buildRequestsPill(),
                ),

                // Top-Right: GPS Location Target Button
                Positioned(
                  top: 14,
                  right: 16,
                  child: _buildGpsButton(),
                ),

                // Pins Overlay
                LayoutBuilder(
                  builder: (context, constraints) {
                    return Stack(
                      children: _pins.map((pin) {
                        final posX = constraints.maxWidth * pin.relativeX;
                        final posY = constraints.maxHeight * pin.relativeY;

                        return Positioned(
                          left: posX - 60,
                          top: posY - 68,
                          child: _MapPinWidget(
                            pinData: pin,
                            isSelected: _selectedPinId == pin.id,
                            onTap: () {
                              setState(() {
                                _selectedPinId = pin.id;
                              });
                              _showPinDetailSheet(pin);
                            },
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),

                // Bottom Floating Action Button: "New Meetup Request"
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: mediaQuery.padding.bottom > 0
                      ? mediaQuery.padding.bottom + 12
                      : 28,
                  child: Center(
                    child: _buildNewMeetupButton(),
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
  // TOP BAR: Profile avatar with outer ring + Notification Bell
  // -------------------------------------------------------------
  Widget _buildTopBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Avatar with purple halo ring -> Opens Profile Modal
        GestureDetector(
          onTap: _showProfileSheet,
          child: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFF3F4FD),
              border: Border.all(
                color: const Color(0xFF7C4DFF).withOpacity(0.35),
                width: 3.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF7C4DFF).withOpacity(0.2),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(2.5),
              child: Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF6C3EE8),
                ),
                child: const Icon(
                  Icons.person,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),
          ),
        ),

        // Notification Bell with purple indicator dot -> Opens Notifications Sheet
        GestureDetector(
          onTap: _showNotificationsSheet,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                child: const Icon(
                  Icons.notifications_none_rounded,
                  color: Color(0xFF222038),
                  size: 28,
                ),
              ),
              Positioned(
                right: 6,
                top: 5,
                child: Container(
                  width: 8.5,
                  height: 8.5,
                  decoration: BoxDecoration(
                    color: const Color(0xFF6C3EE8),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // SECTION HEADER: Sparkle + "Your top match" + Subtitle
  // -------------------------------------------------------------
  Widget _buildSectionHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: const [
            Icon(
              Icons.auto_awesome,
              color: Color(0xFF6C3EE8),
              size: 20,
            ),
            SizedBox(width: 8),
            Text(
              'Your top match',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1E1B2E),
                letterSpacing: -0.4,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          'Someone you might want to meet right now ✨',
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w400,
            color: Color(0xFF5C5B72),
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // TOP MATCH CARD: Grab coffee ☕, details, and View button
  // -------------------------------------------------------------
  Widget _buildTopMatchCard() {
    final currentCard = _matchCards[_selectedCardIndex];

    return GestureDetector(
      onTap: () => _showTopMatchDetailSheet(currentCard),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF382068).withOpacity(0.07),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            // Coffee / Activity Illustration
            _buildCoffeeIllustration(currentCard['emoji']),
            const SizedBox(width: 14),

            // Details column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    currentCard['title'],
                    style: const TextStyle(
                      fontSize: 16.5,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1E1B2E),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    currentCard['subtitle'],
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF6D6B82),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),

                  // Time and Distance row
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time_rounded,
                        size: 13,
                        color: Color(0xFF6C3EE8),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        currentCard['time'],
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF6C3EE8),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 6.0),
                        child: Text(
                          '|',
                          style: TextStyle(
                            color: Color(0xFFD4D3E2),
                            fontSize: 12,
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.location_on_rounded,
                        size: 13,
                        color: Color(0xFF6C3EE8),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        currentCard['distance'],
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF6C3EE8),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // "View >" Gradient Pill Button
            GestureDetector(
              onTap: () => _showTopMatchDetailSheet(currentCard),
              child: Container(
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF6836E6),
                      Color(0xFF9854FF),
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
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
                    Text(
                      'View',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    SizedBox(width: 3),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: Colors.white,
                      size: 17,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // COFFEE ILLUSTRATION: Soft purple circular badge with sparkles
  // -------------------------------------------------------------
  Widget _buildCoffeeIllustration([String emoji = '☕']) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 62,
          height: 62,
          decoration: const BoxDecoration(
            color: Color(0xFFDEDCF7),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Container(
              width: 50,
              height: 50,
              decoration: const BoxDecoration(
                color: Color(0xFFC7C2F2),
                shape: BoxShape.circle,
              ),
              child: Center(
                // 3D styled coffee cup / emoji graphic
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      )
                    ],
                  ),
                  child: Center(
                    child: Text(
                      emoji,
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        // Decorative sparkles around the badge
        const Positioned(
          top: 2,
          right: 0,
          child: Text(
            '✦',
            style: TextStyle(
              color: Color(0xFF9F75FF),
              fontSize: 10,
            ),
          ),
        ),
        const Positioned(
          bottom: 2,
          left: 0,
          child: Text(
            '✦',
            style: TextStyle(
              color: Color(0xFF9F75FF),
              fontSize: 10,
            ),
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // PAGINATION DOTS (Interactive Tap to switch cards)
  // -------------------------------------------------------------
  Widget _buildPaginationDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        _matchCards.length,
        (index) => GestureDetector(
          onTap: () {
            setState(() {
              _selectedCardIndex = index;
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            margin: const EdgeInsets.symmetric(horizontal: 2.5),
            width: _selectedCardIndex == index ? 14 : 6,
            height: 6,
            decoration: BoxDecoration(
              color: _selectedCardIndex == index
                  ? const Color(0xFF6C3EE8)
                  : const Color(0xFFD3D1E5),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // MAP TOP-LEFT: "4 requests on the map" Dropdown Pill
  // -------------------------------------------------------------
  Widget _buildRequestsPill() {
    return GestureDetector(
      onTap: _showRequestsListSheet,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(
              Icons.people_alt_rounded,
              color: Color(0xFF6C3EE8),
              size: 17,
            ),
            SizedBox(width: 6),
            Text(
              '4 requests on the map',
              style: TextStyle(
                color: Color(0xFF6C3EE8),
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              color: Color(0xFF6C3EE8),
              size: 19,
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // MAP TOP-RIGHT: GPS Target Circle Button
  // -------------------------------------------------------------
  Widget _buildGpsButton() {
    return GestureDetector(
      onTap: _showGpsFeedback,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: const Center(
          child: Icon(
            Icons.my_location_rounded,
            color: Color(0xFF6C3EE8),
            size: 21,
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // BOTTOM BUTTON: "+ New Meetup Request"
  // -------------------------------------------------------------
  Widget _buildNewMeetupButton() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DateTimeSetupPage(
              onBack: () => Navigator.pop(context),
              onRequestMeetup: (activity, people, place, hour, minute, isAm) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Meetup requested: $activity ($people people) at $place! 🚀',
                    ),
                    backgroundColor: const Color(0xFF6C3EE8),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 26),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFF5A25E6),
              Color(0xFF8E45FF),
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6C3EE8).withOpacity(0.45),
              blurRadius: 18,
              spreadRadius: 1,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(
              Icons.add_circle_outline_rounded,
              color: Colors.white,
              size: 21,
            ),
            SizedBox(width: 9),
            Text(
              'New Meetup Request',
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =============================================================
  // BOTTOM SHEETS & INTERACTIVE MODALS
  // =============================================================

  // 1. New Meetup Request Modal Form
  void _showNewMeetupSheet() {
    String selectedActivity = 'Coffee ☕';
    final activities = ['Coffee ☕', 'Walk 🚶', 'Brunch 🥐', 'Explore 🌉', 'Hangout 🎉'];
    final noteController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              padding: EdgeInsets.only(
                top: 20,
                left: 24,
                right: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle Bar
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

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'New Meetup Request',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1E1B2E),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const Text(
                    'Post a quick request for people nearby to join you.',
                    style: TextStyle(fontSize: 13, color: Color(0xFF6D6B82)),
                  ),
                  const SizedBox(height: 16),

                  // Category Selector
                  const Text(
                    'What are you looking to do?',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E1B2E)),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: activities.map((act) {
                      final isSelected = selectedActivity == act;
                      return GestureDetector(
                        onTap: () {
                          setSheetState(() {
                            selectedActivity = act;
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFF6C3EE8) : const Color(0xFFF1F1F8),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Text(
                            act,
                            style: TextStyle(
                              color: isSelected ? Colors.white : const Color(0xFF1E1B2E),
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // Message Input
                  const Text(
                    'Add a brief note',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E1B2E)),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: noteController,
                    decoration: InputDecoration(
                      hintText: 'e.g. Grabbing an iced latte, free for 30 mins...',
                      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                      filled: true,
                      fillColor: const Color(0xFFF6F6FC),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Post Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                                const SizedBox(width: 8),
                                Text('Posted "$selectedActivity" to the map! 🎉'),
                              ],
                            ),
                            backgroundColor: const Color(0xFF6C3EE8),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6C3EE8),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                      ),
                      child: const Text(
                        'Post Request to Map',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // 2. Top Match Detail Sheet
  void _showTopMatchDetailSheet(Map<String, dynamic> match) {
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
            crossAxisAlignment: CrossAxisAlignment.start,
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

              Row(
                children: [
                  _buildCoffeeIllustration(match['emoji']),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          match['title'],
                          style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1E1B2E),
                          ),
                        ),
                        Text(
                          'Posted by ${match['person']}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF6C3EE8),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF6F6FD),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  match['bio'],
                  style: const TextStyle(color: Color(0xFF4A4960), fontSize: 13.5, height: 1.4),
                ),
              ),
              const SizedBox(height: 14),

              Row(
                children: [
                  const Icon(Icons.location_on, size: 16, color: Color(0xFF6C3EE8)),
                  const SizedBox(width: 4),
                  Text(match['place'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const Spacer(),
                  Text(match['distance'], style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
              const SizedBox(height: 22),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      child: const Text('Pass', style: TextStyle(color: Colors.grey)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Connected with ${match['person']}! ☕'),
                            backgroundColor: const Color(0xFF6C3EE8),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6C3EE8),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      child: const Text('Accept & Say Hi 👋', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              )
            ],
          ),
        );
      },
    );
  }

  // 3. Map Pin Detail Sheet
  void _showPinDetailSheet(MapPinData pin) {
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
            crossAxisAlignment: CrossAxisAlignment.start,
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
              const SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    pin.title.replaceAll('\n', ' '),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1E1B2E)),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF1FE),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      pin.time,
                      style: const TextStyle(color: Color(0xFF6C3EE8), fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'By ${pin.author} • ${pin.distance}',
                style: const TextStyle(color: Color(0xFF6D6B82), fontSize: 13),
              ),
              const SizedBox(height: 14),

              Text(
                pin.description,
                style: const TextStyle(color: Color(0xFF333344), fontSize: 14, height: 1.4),
              ),
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Requested to join ${pin.author}! ✨'),
                        backgroundColor: const Color(0xFF6C3EE8),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C3EE8),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  ),
                  child: const Text('Join This Meetup 🚀', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // 4. Requests List Bottom Sheet (Dropdown button)
  void _showRequestsListSheet() {
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
            crossAxisAlignment: CrossAxisAlignment.start,
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
              const SizedBox(height: 16),
              const Text(
                'Active Requests on the Map',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1E1B2E)),
              ),
              const SizedBox(height: 12),

              ..._pins.map((p) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 42,
                  height: 42,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEFF1FE),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.location_on, color: Color(0xFF6C3EE8), size: 20),
                ),
                title: Text(p.title.replaceAll('\n', ' '), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: Text('${p.author} • ${p.time} (${p.distance})', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                trailing: const Icon(Icons.chevron_right, color: Color(0xFF6C3EE8)),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _selectedPinId = p.id;
                  });
                  _showPinDetailSheet(p);
                },
              )),
            ],
          ),
        );
      },
    );
  }

  // 5. GPS Feedback
  void _showGpsFeedback() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: const [
            Icon(Icons.gps_fixed, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text('📍 Centered on your current location'),
          ],
        ),
        backgroundColor: const Color(0xFF6C3EE8),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // 6. Profile Sheet
  void _showProfileSheet() {
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
              const SizedBox(height: 20),
              Container(
                width: 70,
                height: 70,
                decoration: const BoxDecoration(
                  color: Color(0xFF6C3EE8),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person, color: Colors.white, size: 40),
              ),
              const SizedBox(height: 12),
              const Text(
                'John Ng',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Text('Active Status: Open for coffee ☕', style: TextStyle(color: Color(0xFF6C3EE8), fontSize: 13)),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.edit, color: Color(0xFF6C3EE8)),
                title: const Text('Edit Profile & Status'),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                leading: const Icon(Icons.settings, color: Color(0xFF6C3EE8)),
                title: const Text('Settings & Privacy'),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
    );
  }

  // 7. Notifications Sheet
  void _showNotificationsSheet() {
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
            crossAxisAlignment: CrossAxisAlignment.start,
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
              const SizedBox(height: 16),
              const Text(
                'Notifications 🔔',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 14),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFEFF1FE),
                  child: Icon(Icons.local_cafe, color: Color(0xFF6C3EE8)),
                ),
                title: const Text('Elena accepted your coffee request!'),
                subtitle: const Text('10 mins ago'),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFEFF1FE),
                  child: Icon(Icons.star, color: Color(0xFF6C3EE8)),
                ),
                title: const Text('You have 3 new top matches nearby'),
                subtitle: const Text('1 hour ago'),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
    );
  }
}

// -------------------------------------------------------------
// MODEL: Data for a Map Pin
// -------------------------------------------------------------
class MapPinData {
  final String id;
  final String title;
  final String time;
  final double relativeX;
  final double relativeY;
  final String category;
  final String author;
  final String distance;
  final String description;

  const MapPinData({
    required this.id,
    required this.title,
    required this.time,
    required this.relativeX,
    required this.relativeY,
    this.category = 'General',
    this.author = 'Friend',
    this.distance = '0.5 km away',
    this.description = 'Looking for someone to meetup right now!',
  });
}

// -------------------------------------------------------------
// WIDGET: Map Pin with Tooltip Card + Pointer + Purple Dot
// -------------------------------------------------------------
class _MapPinWidget extends StatelessWidget {
  final MapPinData pinData;
  final bool isSelected;
  final VoidCallback onTap;

  const _MapPinWidget({
    required this.pinData,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Speech Bubble Card
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF6C3EE8) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: isSelected
                      ? const Color(0xFF6C3EE8).withOpacity(0.4)
                      : Colors.black.withOpacity(0.12),
                  blurRadius: isSelected ? 16 : 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  pinData.title,
                  style: TextStyle(
                    color: isSelected ? Colors.white : const Color(0xFF1E1B2E),
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.access_time_rounded,
                      size: 11,
                      color: isSelected ? Colors.white.withOpacity(0.85) : const Color(0xFF6C3EE8),
                    ),
                    const SizedBox(width: 3.5),
                    Text(
                      pinData.time,
                      style: TextStyle(
                        fontSize: 10,
                        color: isSelected ? Colors.white.withOpacity(0.85) : const Color(0xFF6C3EE8),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Downward Pointer Arrow
          CustomPaint(
            size: const Size(14, 8),
            painter: _TrianglePainter(
              color: isSelected ? const Color(0xFF6C3EE8) : Colors.white,
            ),
          ),

          const SizedBox(height: 2),

          // Purple Dot on the Map
          Container(
            width: 13,
            height: 13,
            decoration: BoxDecoration(
              color: const Color(0xFF6C3EE8),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2.5),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6C3EE8).withOpacity(0.4),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
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
// PAINTER: Seamless downward speech bubble pointer
// -------------------------------------------------------------
class _TrianglePainter extends CustomPainter {
  final Color color;

  _TrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _TrianglePainter oldDelegate) =>
      oldDelegate.color != color;
}

// -------------------------------------------------------------
// PAINTER: Stylized Vector Map with Coastlines, Parks & Roads
// -------------------------------------------------------------
class MapBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Base Map Background (Light Urban Land Color)
    final landPaint = Paint()..color = const Color(0xFFF1F1F5);
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), landPaint);

    // 2. Water / Ocean Body (Light Blue)
    final waterPaint = Paint()..color = const Color(0xFFBCE0FD);

    // Top-Left / Harbor Water
    final waterPath1 = Path()
      ..moveTo(0, 0)
      ..lineTo(w * 0.42, 0)
      ..cubicTo(w * 0.38, h * 0.12, w * 0.25, h * 0.22, 0, h * 0.28)
      ..close();
    canvas.drawPath(waterPath1, waterPaint);

    // Top-Right / Ocean Bay
    final waterPath2 = Path()
      ..moveTo(w * 0.55, 0)
      ..lineTo(w, 0)
      ..lineTo(w, h * 0.45)
      ..cubicTo(w * 0.85, h * 0.40, w * 0.68, h * 0.25, w * 0.58, 0)
      ..close();
    canvas.drawPath(waterPath2, waterPaint);

    // 3. Green Park Areas
    final parkPaint = Paint()..color = const Color(0xFFD6F0C5);

    // Top-center park peninsula
    final parkPath1 = Path()
      ..moveTo(w * 0.38, 0)
      ..cubicTo(w * 0.34, h * 0.15, w * 0.32, h * 0.28, w * 0.45, h * 0.32)
      ..cubicTo(w * 0.55, h * 0.34, w * 0.65, h * 0.26, w * 0.62, h * 0.14)
      ..cubicTo(w * 0.60, h * 0.05, w * 0.55, 0, w * 0.50, 0)
      ..close();
    canvas.drawPath(parkPath1, parkPaint);

    // Left small park
    final parkPath2 = Path()
      ..moveTo(0, h * 0.42)
      ..cubicTo(w * 0.18, h * 0.40, w * 0.16, h * 0.52, 0, h * 0.54)
      ..close();
    canvas.drawPath(parkPath2, parkPaint);

    // 4. Street & Block Grid Lines
    final roadBorderPaint = Paint()
      ..color = const Color(0xFFE4E4EC)
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke;

    final roadPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke;

    final minorRoadPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 4.5
      ..style = PaintingStyle.stroke;

    // Diagonal Primary Avenues
    void drawRoad(Path path) {
      canvas.drawPath(path, roadBorderPaint);
      canvas.drawPath(path, roadPaint);
    }

    // Main Avenue 1 (Bottom-left to Top-right)
    final ave1 = Path()
      ..moveTo(-20, h * 0.85)
      ..lineTo(w * 1.1, h * 0.30);
    drawRoad(ave1);

    // Main Avenue 2
    final ave2 = Path()
      ..moveTo(-20, h * 0.60)
      ..lineTo(w * 0.85, 0);
    drawRoad(ave2);

    // Main Avenue 3
    final ave3 = Path()
      ..moveTo(w * 0.15, h + 20)
      ..lineTo(w * 1.1, h * 0.55);
    drawRoad(ave3);

    // Cross Streets (Perpendicular)
    for (double i = 0.1; i <= 1.0; i += 0.18) {
      final crossStreet = Path()
        ..moveTo(w * i - 80, -20)
        ..lineTo(w * i + 100, h + 20);
      canvas.drawPath(crossStreet, minorRoadPaint);
    }

    // Secondary Grid Lines
    for (double i = 0.25; i <= 0.95; i += 0.22) {
      final subAve = Path()
        ..moveTo(-20, h * i)
        ..lineTo(w + 20, h * (i - 0.35));
      canvas.drawPath(subAve, minorRoadPaint);
    }

    // 5. Curved Bridge across water (Top Right)
    final bridgeShadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.08)
      ..strokeWidth = 14
      ..style = PaintingStyle.stroke;

    final bridgePaint = Paint()
      ..color = const Color(0xFFF7F7FA)
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke;

    final bridgeRailingPaint = Paint()
      ..color = const Color(0xFFDADAE2)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final bridgePath = Path()
      ..moveTo(w * 0.45, h * 0.30)
      ..cubicTo(w * 0.65, h * 0.28, w * 0.82, h * 0.22, w * 1.1, h * 0.12);

    canvas.drawPath(bridgePath, bridgeShadowPaint);
    canvas.drawPath(bridgePath, bridgePaint);
    canvas.drawPath(bridgePath, bridgeRailingPaint);

    // 6. Waterfront Promenade / Piers (Left side)
    final pierPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    final pier1 = Path()..moveTo(0, h * 0.18)..lineTo(w * 0.12, h * 0.16);
    final pier2 = Path()..moveTo(0, h * 0.22)..lineTo(w * 0.15, h * 0.20);
    final pier3 = Path()..moveTo(0, h * 0.26)..lineTo(w * 0.10, h * 0.24);
    canvas.drawPath(pier1, pierPaint);
    canvas.drawPath(pier2, pierPaint);
    canvas.drawPath(pier3, pierPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}