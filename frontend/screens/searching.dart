import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;

class SearchingPage extends StatefulWidget {
  final String activity;
  final String people;
  final String place;
  final String time;

  const SearchingPage({
    super.key,
    this.activity = 'Grab coffee ☕',
    this.people = '2',
    this.place = 'Sydney CBD',
    this.time = '8:30 AM',
  });

  @override
  State<SearchingPage> createState() => _SearchingPageState();
}

class _SearchingPageState extends State<SearchingPage> with SingleTickerProviderStateMixin {
  final MapController _mapController = MapController();
  final LatLng _initialCenter = const LatLng(-33.8688, 151.2093); // Sydney CBD & Harbor

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // Real GPS Map Pins in Sydney
  final List<MapPinData> _pins = const [
    MapPinData(
      id: 'pin_1',
      title: 'Wants to grab\ncoffee! ☕',
      time: '15 mins ago',
      location: LatLng(-33.8610, 151.2105),
      category: 'Coffee',
      author: 'Elena R.',
      distance: '0.4 km away',
      description: 'Working at a cafe near Circular Quay, free for the next hour to grab a flat white!',
    ),
    MapPinData(
      id: 'pin_2',
      title: 'Down for\na walk 🚶',
      time: '8 mins ago',
      location: LatLng(-33.8645, 151.2175),
      category: 'Walk',
      author: 'Marcus K.',
      distance: '0.3 km away',
      description: 'Walking along the Botanic Garden harbor path towards Mrs Macquarie Chair. Join in!',
    ),
    MapPinData(
      id: 'pin_3',
      title: 'Brunch\nanyone? 🥐',
      time: '22 mins ago',
      location: LatLng(-33.8825, 151.2135),
      category: 'Food',
      author: 'Sophie T.',
      distance: '0.8 km away',
      description: 'Heading to a bakery in Surry Hills on Crown St. Craving croissants & iced matcha!',
    ),
    MapPinData(
      id: 'pin_4',
      title: 'Open to\nany plans! 🎉',
      time: '12 mins ago',
      location: LatLng(-33.8745, 151.2005),
      category: 'Social',
      author: 'David L.',
      distance: '0.5 km away',
      description: 'Chilling at Darling Quarter! Up for bowling, bubble tea, or gaming.',
    ),
    MapPinData(
      id: 'pin_5',
      title: "Let's explore\nthe city! 🌉",
      time: '5 mins ago',
      location: LatLng(-33.8550, 151.2100),
      category: 'Explore',
      author: 'Chloe M.',
      distance: '0.9 km away',
      description: 'Walking across the Sydney Harbour Bridge! Looking for company to enjoy the views.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
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
          // TOP SECTION (Searching Status Card + Sydney Match Status)
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
                bottom: 18,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Row: Avatar & Notifications
                  _buildTopBar(),
                  const SizedBox(height: 18),

                  // Section Title: "Searching for matches..."
                  _buildSectionHeader(),
                  const SizedBox(height: 14),

                  // Searching Status Card
                  _buildSearchingStatusCard(),
                ],
              ),
            ),
          ),

          // -------------------------------------------------------------
          // BOTTOM SECTION: Live Moving Map with Red Cancel Button
          // -------------------------------------------------------------
          Expanded(
            child: Stack(
              children: [
                // Real Live Moving Map Layer
                Positioned.fill(
                  child: FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: _initialCenter,
                      initialZoom: 14.3,
                      minZoom: 3.0,
                      maxZoom: 18.5,
                      interactionOptions: const InteractionOptions(
                        flags: InteractiveFlag.all,
                      ),
                    ),
                    children: [
                      // CartoDB Voyager Map Tiles (Pastel clean light theme)
                      TileLayer(
                        urlTemplate:
                            'https://basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}@2x.png',
                        fallbackUrl:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.syncshack.meetupapp',
                      ),

                      // User Radar Pulsing Marker
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _initialCenter,
                            width: 90,
                            height: 90,
                            alignment: Alignment.center,
                            child: AnimatedBuilder(
                              animation: _pulseAnimation,
                              builder: (context, child) {
                                return Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Container(
                                      width: 80 * _pulseAnimation.value,
                                      height: 80 * _pulseAnimation.value,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: const Color(0xFF6C3EE8)
                                            .withOpacity(1.0 - _pulseAnimation.value),
                                      ),
                                    ),
                                    Container(
                                      width: 20,
                                      height: 20,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF6C3EE8),
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white, width: 3),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFF6C3EE8).withOpacity(0.5),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          )
                                        ],
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),

                          // Active Sydney Pins
                          ..._pins.map((pin) {
                            return Marker(
                              point: pin.location,
                              width: 140,
                              height: 100,
                              alignment: Alignment.topCenter,
                              child: _MapPinWidget(
                                pinData: pin,
                                onTap: () => _showPinDetailSheet(pin),
                              ),
                            );
                          }),
                        ],
                      ),
                    ],
                  ),
                ),

                // Top-Left: "Searching in Sydney" Pill
                Positioned(
                  top: 14,
                  left: 16,
                  child: _buildSearchingPill(),
                ),

                // Top-Right: GPS Location Target Button
                Positioned(
                  top: 14,
                  right: 16,
                  child: _buildGpsButton(),
                ),

                // Bottom Red Cancel Button: "Cancel Request"
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: mediaQuery.padding.bottom > 0
                      ? mediaQuery.padding.bottom + 12
                      : 28,
                  child: Center(
                    child: _buildCancelButton(),
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
  // TOP BAR: Profile avatar + Back / Notification Bell
  // -------------------------------------------------------------
  Widget _buildTopBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: () => Navigator.of(context).popUntil((route) => route.isFirst),
          child: Container(
            width: 44,
            height: 44,
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
              Icons.arrow_back_ios_new_rounded,
              color: Color(0xFF1E1B2E),
              size: 18,
            ),
          ),
        ),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF6C3EE8).withOpacity(0.12),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 10,
                height: 10,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6C3EE8)),
                ),
              ),
              SizedBox(width: 7),
              Text(
                'LIVE SEARCH',
                style: TextStyle(
                  color: Color(0xFF6C3EE8),
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // SECTION HEADER: Sparkle + "Looking for matches..."
  // -------------------------------------------------------------
  Widget _buildSectionHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Row(
          children: [
            Icon(
              Icons.radar_rounded,
              color: Color(0xFF6C3EE8),
              size: 22,
            ),
            SizedBox(width: 8),
            Text(
              'Finding your match...',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1E1B2E),
                letterSpacing: -0.4,
              ),
            ),
          ],
        ),
        SizedBox(height: 4),
        Text(
          'Broadcasting your request to people nearby in Sydney ✨',
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
  // SEARCHING STATUS CARD: Active Request Summary
  // -------------------------------------------------------------
  Widget _buildSearchingStatusCard() {
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
          // Activity Badge
          Container(
            width: 58,
            height: 58,
            decoration: const BoxDecoration(
              color: Color(0xFFEDE7FA),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text(
                '☕',
                style: TextStyle(fontSize: 26),
              ),
            ),
          ),
          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.activity.isNotEmpty ? widget.activity : 'Grab Coffee ☕',
                  style: const TextStyle(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E1B2E),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${widget.people} people • ${widget.place}',
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF6D6B82),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),

                Row(
                  children: [
                    const Icon(
                      Icons.access_time_rounded,
                      size: 13,
                      color: Color(0xFF6C3EE8),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      widget.time,
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF6C3EE8),
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Icon(
                      Icons.location_on_rounded,
                      size: 13,
                      color: Color(0xFF6C3EE8),
                    ),
                    const SizedBox(width: 3),
                    const Text(
                      'Within 2.0 km',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF6C3EE8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // TOP-LEFT PILL: "Searching nearby..."
  // -------------------------------------------------------------
  Widget _buildSearchingPill() {
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
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.explore_rounded,
            color: Color(0xFF6C3EE8),
            size: 17,
          ),
          SizedBox(width: 6),
          Text(
            'Searching nearby in Sydney...',
            style: TextStyle(
              color: Color(0xFF6C3EE8),
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // TOP-RIGHT: GPS Center Button
  // -------------------------------------------------------------
  Widget _buildGpsButton() {
    return GestureDetector(
      onTap: () => _mapController.move(_initialCenter, 14.5),
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
  // BOTTOM RED CANCEL BUTTON: "Cancel Request"
  // -------------------------------------------------------------
  Widget _buildCancelButton() {
    return GestureDetector(
      onTap: () {
        // Pop back to the HomePage
        Navigator.of(context).popUntil((route) => route.isFirst);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.cancel_outlined, color: Colors.white, size: 19),
                SizedBox(width: 8),
                Text('Meetup request cancelled.'),
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
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 32),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFFE53935),
              Color(0xFFFF5252),
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFE53935).withOpacity(0.45),
              blurRadius: 18,
              spreadRadius: 1,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.close_rounded,
              color: Colors.white,
              size: 21,
            ),
            SizedBox(width: 9),
            Text(
              'Cancel Request',
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }

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
                        content: Text('Matched with ${pin.author}! 🎉'),
                        backgroundColor: const Color(0xFF6C3EE8),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C3EE8),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  ),
                  child: const Text('Connect & Meetup 👋', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// -------------------------------------------------------------
// MODEL: Data for a Map Pin with Real GPS Coordinates
// -------------------------------------------------------------
class MapPinData {
  final String id;
  final String title;
  final String time;
  final LatLng location;
  final String category;
  final String author;
  final String distance;
  final String description;

  const MapPinData({
    required this.id,
    required this.title,
    required this.time,
    required this.location,
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
  final VoidCallback onTap;

  const _MapPinWidget({
    required this.pinData,
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 10,
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
                    fontSize: 11.5,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
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
                        fontSize: 9.5,
                        color: Color(0xFF6C3EE8),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          CustomPaint(
            size: const Size(12, 6),
            painter: _TrianglePainter(color: Colors.white),
          ),

          const SizedBox(height: 1),

          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: const Color(0xFF6C3EE8),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2.2),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6C3EE8).withOpacity(0.45),
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
