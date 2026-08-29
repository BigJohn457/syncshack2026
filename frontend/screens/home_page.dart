import 'package:flutter/material.dart';

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

  // 5 Map Pins matching the exact positions & texts in the screenshot
  final List<MapPinData> _pins = const [
    MapPinData(
      id: 'pin_1',
      title: 'Wants to grab\ncoffee! ☕',
      time: '15 mins ago',
      relativeX: 0.48,
      relativeY: 0.16,
    ),
    MapPinData(
      id: 'pin_2',
      title: 'Down for\na walk 🚶',
      time: '8 mins ago',
      relativeX: 0.26,
      relativeY: 0.43,
    ),
    MapPinData(
      id: 'pin_3',
      title: 'Brunch\nanyone? 🥐',
      time: '22 mins ago',
      relativeX: 0.70,
      relativeY: 0.49,
    ),
    MapPinData(
      id: 'pin_4',
      title: 'Open to\nany plans! 🎉',
      time: '12 mins ago',
      relativeX: 0.31,
      relativeY: 0.72,
    ),
    MapPinData(
      id: 'pin_5',
      title: "Let's explore\nthe city! 🌉",
      time: '5 mins ago',
      relativeX: 0.78,
      relativeY: 0.76,
    ),
  ];

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
                                _selectedPinId =
                                    (_selectedPinId == pin.id) ? null : pin.id;
                              });
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
        // Avatar with purple halo ring
        Container(
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

        // Notification Bell with purple indicator dot
        GestureDetector(
          onTap: () {},
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
    return Container(
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
          // Coffee cup graphic in lavender circle with sparkles
          _buildCoffeeIllustration(),
          const SizedBox(width: 14),

          // Details column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Grab coffee ☕',
                  style: TextStyle(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E1B2E),
                  ),
                ),
                const SizedBox(height: 3),
                const Text(
                  'Looking for a coffee buddy nearby!',
                  style: TextStyle(
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
                  children: const [
                    Icon(
                      Icons.access_time_rounded,
                      size: 13,
                      color: Color(0xFF6C3EE8),
                    ),
                    SizedBox(width: 4),
                    Text(
                      '15 mins ago',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF6C3EE8),
                      ),
                    ),
                    Padding(
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
                    Icon(
                      Icons.location_on_rounded,
                      size: 13,
                      color: Color(0xFF6C3EE8),
                    ),
                    SizedBox(width: 3),
                    Text(
                      '0.4 km away',
                      style: TextStyle(
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
          Container(
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
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // COFFEE ILLUSTRATION: Soft purple circular badge with sparkles
  // -------------------------------------------------------------
  Widget _buildCoffeeIllustration() {
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
                // 3D styled coffee cup graphic
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
                  child: const Center(
                    child: Icon(
                      Icons.coffee_rounded,
                      color: Color(0xFF6C3EE8),
                      size: 20,
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
  // PAGINATION DOTS
  // -------------------------------------------------------------
  Widget _buildPaginationDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: _selectedCardIndex == 0 ? 14 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: _selectedCardIndex == 0
                ? const Color(0xFF6C3EE8)
                : const Color(0xFFD3D1E5),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 4),
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: _selectedCardIndex == 1 ? 14 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: _selectedCardIndex == 1
                ? const Color(0xFF6C3EE8)
                : const Color(0xFFD3D1E5),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // MAP TOP-LEFT: "4 requests on the map" Dropdown Pill
  // -------------------------------------------------------------
  Widget _buildRequestsPill() {
    return Container(
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
    );
  }

  // -------------------------------------------------------------
  // MAP TOP-RIGHT: GPS Target Circle Button
  // -------------------------------------------------------------
  Widget _buildGpsButton() {
    return Container(
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
    );
  }

  // -------------------------------------------------------------
  // BOTTOM BUTTON: "+ New Meetup Request"
  // -------------------------------------------------------------
  Widget _buildNewMeetupButton() {
    return Container(
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

  const MapPinData({
    required this.id,
    required this.title,
    required this.time,
    required this.relativeX,
    required this.relativeY,
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 12,
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
                  style: const TextStyle(
                    color: Color(0xFF1E1B2E),
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.access_time_rounded,
                      size: 11,
                      color: Color(0xFF6C3EE8),
                    ),
                    const SizedBox(width: 3.5),
                    Text(
                      pinData.time,
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF6C3EE8),
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
            painter: _TrianglePainter(color: Colors.white),
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
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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