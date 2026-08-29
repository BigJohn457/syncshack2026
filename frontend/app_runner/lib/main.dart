import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart' hide Path;

import 'auth/auth_page.dart';
import 'auth/auth_api.dart';
import 'chat.dart';
import 'datetime.dart';
import 'edit_profile.dart';
import 'requests/nearby_requests_api.dart';
import 'settings.dart';

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
      home: const AuthPage(),
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
  String _userName = 'John Ng';
  String _userStatus = 'Open for coffee ☕';

  // Map Controller for interactive moving/zooming
  final MapController _mapController = MapController();
  final NearbyRequestsApi _nearbyRequestsApi = NearbyRequestsApi();
  static const LatLng _fallbackCenter = LatLng(-33.8688, 151.2093);
  static const double _defaultRadiusKm = 2;
  static const double _defaultZoom = 14.5;
  LatLng? _userLocation;
  double _radiusKm = _defaultRadiusKm;
  double _lastZoom = _defaultZoom;
  bool _mapReady = false;
  bool _loadingRequests = false;
  String? _mapError;
  Timer? _zoomDebounce;

  // Match Cards Data
  final List<Map<String, dynamic>> _matchCards = [
    {
      'title': 'Grab coffee ☕',
      'subtitle': 'Looking for a coffee buddy nearby!',
      'time': '15 mins ago',
      'distance': '0.4 km away',
      'emoji': '☕',
      'person': 'Alex Rivera',
      'place': 'Single O / Surry Hills',
      'bio':
          'Taking a study break near Central, would love a flat white and quick chat!',
    },
    {
      'title': 'Afternoon Walk 🚶',
      'subtitle': 'Going for a brisk walk along the harbor!',
      'time': '8 mins ago',
      'distance': '0.3 km away',
      'emoji': '🚶',
      'person': 'Jordan Lee',
      'place': 'Barangaroo Foreshore',
      'bio':
          'Enjoying the Sydney sunshine. Down for a 20-minute walk by the water.',
    },
  ];

  List<MapPinData> _pins = const [];

  @override
  void initState() {
    super.initState();
    _loadPhoneLocation();
  }

  @override
  void dispose() {
    _zoomDebounce?.cancel();
    super.dispose();
  }

  Future<void> _loadPhoneLocation() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw const AuthException(
          'Turn on Location Services to see nearby requests.',
        );
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied) {
        throw const AuthException(
          'Location permission is required to find nearby requests.',
        );
      }
      if (permission == LocationPermission.deniedForever) {
        throw const AuthException(
          'Location permission is disabled. Enable it in your phone settings.',
        );
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      final location = LatLng(position.latitude, position.longitude);
      if (!mounted) return;
      setState(() {
        _userLocation = location;
        _mapError = null;
      });
      if (_mapReady) _mapController.move(location, _defaultZoom);
      await _fetchNearbyRequests();
    } on AuthException catch (error) {
      if (mounted) setState(() => _mapError = error.message);
    } on Exception {
      if (mounted) {
        setState(
          () => _mapError = 'Could not determine your current location.',
        );
      }
    }
  }

  Future<void> _fetchNearbyRequests() async {
    final location = _userLocation;
    if (location == null) return;
    setState(() {
      _loadingRequests = true;
      _mapError = null;
    });
    try {
      final requests = await _nearbyRequestsApi.fetch(
        latitude: location.latitude,
        longitude: location.longitude,
        radiusKm: _radiusKm,
      );
      if (!mounted) return;
      const distance = Distance();
      setState(() {
        _pins = requests.map((request) {
          final metres = distance(location, request.location);
          return MapPinData(
            id: request.id,
            title: request.title,
            time: _formatMeetTime(request.meetTime),
            location: request.location,
            category: 'Meetup',
            author: 'Nearby member',
            distance: '${(metres / 1000).toStringAsFixed(1)} km away',
            description:
                '${request.placeName} • ${request.minPeople}-${request.maxPeople} people',
          );
        }).toList();
      });
    } on AuthException catch (error) {
      if (mounted) setState(() => _mapError = error.message);
    } finally {
      if (mounted) setState(() => _loadingRequests = false);
    }
  }

  String _formatMeetTime(DateTime? time) {
    if (time == null) return 'Time TBC';
    final local = time.toLocal();
    final hour = local.hour == 0
        ? 12
        : (local.hour > 12 ? local.hour - 12 : local.hour);
    final minute = local.minute.toString().padLeft(2, '0');
    final suffix = local.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $suffix';
  }

  void _onMapPositionChanged(MapCamera camera, bool hasGesture) {
    if (!hasGesture || (camera.zoom - _lastZoom).abs() < 0.05) return;
    _lastZoom = camera.zoom;
    _zoomDebounce?.cancel();
    _zoomDebounce = Timer(const Duration(milliseconds: 500), () {
      final newRadius =
          (_defaultRadiusKm * math.pow(2, _defaultZoom - camera.zoom))
              .clamp(0.1, 50.0)
              .toDouble();
      if ((newRadius - _radiusKm).abs() < 0.05) return;
      setState(() => _radiusKm = newRadius);
      _fetchNearbyRequests();
    });
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
          // BOTTOM SECTION: Interactive Live Moving Map (FlutterMap API)
          // -------------------------------------------------------------
          Expanded(
            child: Stack(
              children: [
                // Real Live Moving Map Layer
                Positioned.fill(
                  child: FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: _fallbackCenter,
                      initialZoom: _defaultZoom,
                      minZoom: 3.0,
                      maxZoom: 18.5,
                      onMapReady: () {
                        _mapReady = true;
                        final location = _userLocation;
                        if (location != null) {
                          _mapController.move(location, _defaultZoom);
                        }
                      },
                      onPositionChanged: _onMapPositionChanged,
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

                      // Interactive Live GPS Pins Layer
                      MarkerLayer(
                        markers: _pins.map((pin) {
                          final isSelected = _selectedPinId == pin.id;
                          return Marker(
                            point: pin.location,
                            width: 160,
                            height: 120,
                            alignment: Alignment.topCenter,
                            child: _MapPinWidget(
                              pinData: pin,
                              isSelected: isSelected,
                              onTap: () {
                                setState(() {
                                  _selectedPinId = pin.id;
                                });
                                _mapController.move(pin.location, 15.0);
                                _showPinDetailSheet(pin);
                              },
                            ),
                          );
                        }).toList(),
                      ),
                      if (_userLocation != null)
                        CircleLayer(
                          circles: [
                            CircleMarker(
                              point: _userLocation!,
                              radius: 8,
                              color: const Color(0xFF6C3EE8),
                              borderColor: Colors.white,
                              borderStrokeWidth: 3,
                            ),
                          ],
                        ),
                    ],
                  ),
                ),

                // Top-Left: "4 requests on the map" Dropdown Pill
                Positioned(top: 14, left: 16, child: _buildRequestsPill()),

                // Top-Right: GPS Location Target Button (Smooth camera centering)
                Positioned(top: 14, right: 16, child: _buildGpsButton()),

                if (_loadingRequests)
                  const Positioned(
                    top: 64,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Card(
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 9,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox.square(
                                dimension: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                              SizedBox(width: 8),
                              Text('Loading nearby requests…'),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                if (_mapError != null && !_loadingRequests)
                  Positioned(
                    top: 64,
                    left: 16,
                    right: 16,
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.location_off_outlined,
                              color: Colors.redAccent,
                            ),
                            const SizedBox(width: 8),
                            Expanded(child: Text(_mapError!)),
                            TextButton(
                              onPressed: _loadPhoneLocation,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                // Bottom Floating Action Button: "New Meetup Request" -> Goes to datetime.dart
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: mediaQuery.padding.bottom > 0
                      ? mediaQuery.padding.bottom + 12
                      : 28,
                  child: Center(child: _buildNewMeetupButton()),
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
                child: const Icon(Icons.person, color: Colors.white, size: 28),
              ),
            ),
          ),
        ),

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
            Icon(Icons.auto_awesome, color: Color(0xFF6C3EE8), size: 20),
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
            _buildCoffeeIllustration(currentCard['emoji']),
            const SizedBox(width: 14),

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

                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
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
                          padding: EdgeInsets.symmetric(horizontal: 5.0),
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
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            GestureDetector(
              onTap: () => _showTopMatchDetailSheet(currentCard),
              child: Container(
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6836E6), Color(0xFF9854FF)],
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
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(emoji, style: const TextStyle(fontSize: 18)),
                  ),
                ),
              ),
            ),
          ),
        ),
        const Positioned(
          top: 2,
          right: 0,
          child: Text(
            '✦',
            style: TextStyle(color: Color(0xFF9F75FF), fontSize: 10),
          ),
        ),
        const Positioned(
          bottom: 2,
          left: 0,
          child: Text(
            '✦',
            style: TextStyle(color: Color(0xFF9F75FF), fontSize: 10),
          ),
        ),
      ],
    );
  }

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
          children: [
            const Icon(
              Icons.people_alt_rounded,
              color: Color(0xFF6C3EE8),
              size: 17,
            ),
            const SizedBox(width: 6),
            Text(
              '${_pins.length} requests • ${_radiusKm.toStringAsFixed(1)} km',
              style: const TextStyle(
                color: Color(0xFF6C3EE8),
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
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
  // MAP TOP-RIGHT: GPS Target Circle Button (Moves Camera)
  // -------------------------------------------------------------
  Widget _buildGpsButton() {
    return GestureDetector(
      onTap: () async {
        if (_userLocation == null) {
          await _loadPhoneLocation();
          return;
        }
        _mapController.move(_userLocation!, _defaultZoom);
        setState(() {
          _lastZoom = _defaultZoom;
          _radiusKm = _defaultRadiusKm;
        });
        await _fetchNearbyRequests();
        if (mounted) _showGpsFeedback();
      },
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
  // BOTTOM BUTTON: "+ New Meetup Request" -> DateTimeSetupPage
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
            colors: [Color(0xFF5A25E6), Color(0xFF8E45FF)],
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
              'Request',
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
  // MODALS & DETAIL SHEETS
  // =============================================================

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
                  style: const TextStyle(
                    color: Color(0xFF4A4960),
                    fontSize: 13.5,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 14),

              Row(
                children: [
                  const Icon(
                    Icons.location_on,
                    size: 16,
                    color: Color(0xFF6C3EE8),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    match['place'],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    match['distance'],
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 22),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Text(
                        'Pass',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatPage(
                              matchName: match['person'].toString(),
                              activity: match['title'].toString(),
                              place: match['place'].toString(),
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6C3EE8),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Text(
                        'Accept & Say Hi 👋',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
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
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1E1B2E),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF1FE),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      pin.time,
                      style: const TextStyle(
                        color: Color(0xFF6C3EE8),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
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
                style: const TextStyle(
                  color: Color(0xFF333344),
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatPage(
                          matchName: pin.author,
                          activity: pin.title.replaceAll('\n', ' '),
                          place: pin.category,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C3EE8),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: const Text(
                    'Join This Meetup 🚀',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

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
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E1B2E),
                ),
              ),
              const SizedBox(height: 12),

              ..._pins.map(
                (p) => ListTile(
                  contentPadding: EdgeInsets.zero,
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
                      size: 20,
                    ),
                  ),
                  title: Text(
                    p.title.replaceAll('\n', ' '),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  subtitle: Text(
                    '${p.author} • ${p.time} (${p.distance})',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  trailing: const Icon(
                    Icons.chevron_right,
                    color: Color(0xFF6C3EE8),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() {
                      _selectedPinId = p.id;
                    });
                    _mapController.move(p.location, 15.5);
                    _showPinDetailSheet(p);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

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
              Text(
                _userName,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                'Active Status: $_userStatus',
                style: const TextStyle(color: Color(0xFF6C3EE8), fontSize: 13),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.edit, color: Color(0xFF6C3EE8)),
                title: const Text('Edit Profile & Status'),
                onTap: () async {
                  Navigator.pop(context);
                  final result = await Navigator.push<Map<String, String>>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EditProfilePage(
                        currentName: _userName,
                        currentStatus: _userStatus,
                      ),
                    ),
                  );
                  if (result != null && mounted) {
                    setState(() {
                      _userName = result['name'] ?? _userName;
                      _userStatus = result['status'] ?? _userStatus;
                    });
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.settings, color: Color(0xFF6C3EE8)),
                title: const Text('Settings & Privacy'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SettingsPage(
                        onLogOut: () {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(builder: (_) => const AuthPage()),
                            (route) => false,
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

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
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ChatPage(
                        matchName: 'Elena R.',
                        activity: 'Coffee Meetup',
                      ),
                    ),
                  );
                },
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
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF6C3EE8) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: isSelected
                      ? const Color(0xFF6C3EE8).withOpacity(0.4)
                      : Colors.black.withOpacity(0.14),
                  blurRadius: isSelected ? 16 : 10,
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
                    fontSize: 11.5,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.access_time_rounded,
                      size: 11,
                      color: isSelected
                          ? Colors.white.withOpacity(0.85)
                          : const Color(0xFF6C3EE8),
                    ),
                    const SizedBox(width: 3.5),
                    Text(
                      pinData.time,
                      style: TextStyle(
                        fontSize: 9.5,
                        color: isSelected
                            ? Colors.white.withOpacity(0.85)
                            : const Color(0xFF6C3EE8),
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
            painter: _TrianglePainter(
              color: isSelected ? const Color(0xFF6C3EE8) : Colors.white,
            ),
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
