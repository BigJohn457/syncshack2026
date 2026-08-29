import 'dart:async';

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import 'auth/auth_api.dart';
import 'chat.dart';
import 'requests/active_request_store.dart';
import 'requests/meetup_requests_api.dart';
import 'requests/place_search_api.dart';
import 'searching.dart';

// "hey!" brand palette
const _kPurple = Color(0xFF7C4DFF);
const _kPurpleDark = Color(0xFF6C3CE0);
const _kCream = Color(0xFFFBF7F2);
const _kLavender = Color(0xFFEDE7FA);
const _kLavenderCard = Color(0xFFE7DFFB);
const _kMinuteBg = Color(0xFFEFEAF8);
const _kHeading = Color(0xFF241B3A);

class DateTimeSetupPage extends StatefulWidget {
  final String currentUserAvatarUrl;
  final LatLng? initialLocation;
  final VoidCallback? onBack;
  final void Function(
    String activity,
    String people,
    String place,
    int hour,
    int minute,
    bool isAm,
  )?
  onRequestMeetup;

  const DateTimeSetupPage({
    super.key,
    this.currentUserAvatarUrl = '',
    this.initialLocation,
    this.onBack,
    this.onRequestMeetup,
  });

  @override
  State<DateTimeSetupPage> createState() => _DateTimeSetupPageState();
}

class _DateTimeSetupPageState extends State<DateTimeSetupPage> {
  final _formKey = GlobalKey<FormState>();
  final _api = MeetupRequestsApi();
  final _placeSearchApi = PlaceSearchApi();
  final _activityController = TextEditingController();
  final _placeController = TextEditingController();

  int _minPeople = 1;
  int _maxPeople = 2;
  int _hour = 8;
  int _minute = 30;
  bool _isAm = true;
  bool _isSubmitting = false;
  bool _isSearchingPlaces = false;
  String? _submitError;
  String? _placeError;
  PlaceSearchResult? _selectedPlace;
  List<PlaceSearchResult> _placeSuggestions = const [];
  Timer? _placeSearchDebounce;
  int _placeSearchGeneration = 0;

  @override
  void dispose() {
    _activityController.dispose();
    _placeController.dispose();
    _placeSearchDebounce?.cancel();
    _placeSearchApi.close();
    super.dispose();
  }

  void _cycleHour() {
    setState(() => _hour = _hour == 12 ? 1 : _hour + 1);
  }

  void _cycleMinute() {
    setState(() => _minute = (_minute + 5) % 60);
  }

  void _onPlaceQueryChanged(String query) {
    _placeSearchDebounce?.cancel();
    final generation = ++_placeSearchGeneration;
    setState(() {
      _selectedPlace = null;
      _placeError = null;
      if (query.trim().length < 3) _placeSuggestions = const [];
    });
    if (query.trim().length < 3) return;
    if (!_placeSearchApi.isConfigured) {
      setState(() {
        _placeError = 'Geoapify API key is not configured.';
        _placeSuggestions = const [];
      });
      return;
    }

    _placeSearchDebounce = Timer(const Duration(milliseconds: 450), () async {
      setState(() => _isSearchingPlaces = true);
      try {
        final results = await _placeSearchApi.search(
          query,
          near: widget.initialLocation,
        );
        if (!mounted || generation != _placeSearchGeneration) return;
        setState(() {
          _placeSuggestions = results;
          if (results.isEmpty) _placeError = 'No matching places found';
        });
      } on Exception {
        if (mounted && generation == _placeSearchGeneration) {
          setState(() => _placeError = 'Could not search places. Try again.');
        }
      } finally {
        if (mounted && generation == _placeSearchGeneration) {
          setState(() => _isSearchingPlaces = false);
        }
      }
    });
  }

  void _selectPlace(PlaceSearchResult place) {
    setState(() {
      _selectedPlace = place;
      _placeSuggestions = const [];
      _placeError = null;
      _placeController.value = TextEditingValue(
        text: place.address,
        selection: TextSelection.collapsed(offset: place.address.length),
      );
    });
  }

  DateTime _nextMeetTime() {
    final now = DateTime.now();
    var hour24 = _hour % 12;
    if (!_isAm) hour24 += 12;
    var result = DateTime(now.year, now.month, now.day, hour24, _minute);
    if (!result.isAfter(now)) result = result.add(const Duration(days: 1));
    return result;
  }

  Future<void> _submitMeetup() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isSubmitting = true;
      _submitError = null;
    });

    try {
      final activeRequest = await ActiveRequestStore.load();
      if (activeRequest != null) {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => activeRequest.isFull
                ? ChatPage(
                    activity: activeRequest.activity,
                    place: activeRequest.place,
                    meetupId: activeRequest.meetupId,
                  )
                : SearchingPage.fromRequest(activeRequest),
          ),
        );
        return;
      }
      final selectedPlace = _selectedPlace;
      if (selectedPlace == null) {
        throw const AuthException('Search for and select a place first.');
      }
      final location = selectedPlace.location;
      final placeName = selectedPlace.address;
      final meetTime = _nextMeetTime();
      final createdRequest = await _api.create(
        title: _activityController.text,
        minPeople: _minPeople,
        maxPeople: _maxPeople,
        meetTime: meetTime,
        location: location,
        placeName: placeName,
        expiresAt: meetTime.add(const Duration(minutes: 30)),
      );
      if (!mounted) return;

      final active = ActiveMeetupRequest(
        id: createdRequest['request_id']?.toString() ?? '',
        activity: _activityController.text.trim(),
        people: '$_minPeople-$_maxPeople',
        place: placeName,
        time:
            '${_hour.toString().padLeft(2, '0')}:${_minute.toString().padLeft(2, '0')} ${_isAm ? "AM" : "PM"}',
        latitude: location.latitude,
        longitude: location.longitude,
        expiresAt: meetTime.add(const Duration(minutes: 30)),
        acceptedCount: (createdRequest['accepted_count'] as num?)?.toInt() ?? 0,
        meetupId: createdRequest['meetup_id']?.toString() ?? '',
      );
      await ActiveRequestStore.save(active);
      if (!mounted) return;

      widget.onRequestMeetup?.call(
        _activityController.text,
        _maxPeople.toString(),
        placeName,
        _hour,
        _minute,
        _isAm,
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => SearchingPage.fromRequest(active),
        ),
      );
    } on AuthException catch (error) {
      if (mounted) setState(() => _submitError = error.message);
    } on Exception {
      if (mounted) {
        setState(
          () => _submitError = 'Could not create the meetup. Try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kCream,
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _TopBar(
                      currentUserAvatarUrl: widget.currentUserAvatarUrl,
                      onBack: widget.onBack,
                    ),
                    const SizedBox(height: 28),
                    const Text(
                      'What do you\nwant to do today?',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        height: 1.15,
                        color: _kHeading,
                      ),
                    ),
                    const SizedBox(height: 28),
                    _FieldPill(
                      icon: Icons.auto_fix_high,
                      hint: 'Activity',
                      controller: _activityController,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _NumberDropdownPill(
                            icon: Icons.people_outline_rounded,
                            label: 'Min people',
                            value: _minPeople,
                            values: List.generate(20, (index) => index + 1),
                            onChanged: (value) {
                              if (value == null) return;
                              setState(() {
                                _minPeople = value;
                                if (_maxPeople < value) _maxPeople = value;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _NumberDropdownPill(
                            icon: Icons.people_alt_rounded,
                            label: 'Max people',
                            value: _maxPeople,
                            values: List.generate(
                              21 - _minPeople,
                              (index) => index + _minPeople,
                            ),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _maxPeople = value);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _FieldPill(
                      icon: Icons.location_on_rounded,
                      hint: 'Start typing a place or address',
                      controller: _placeController,
                      keyboardType: TextInputType.streetAddress,
                      onChanged: _onPlaceQueryChanged,
                      trailing: _isSearchingPlaces
                          ? const Padding(
                              padding: EdgeInsets.all(10),
                              child: SizedBox.square(
                                dimension: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            )
                          : const Icon(Icons.search_rounded, color: _kPurple),
                      validator: (_) => _selectedPlace == null
                          ? 'Choose a place from the suggestions'
                          : null,
                    ),
                    if (_placeSuggestions.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(top: 8),
                        constraints: const BoxConstraints(maxHeight: 260),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: _kPurpleDark.withValues(alpha: 0.10),
                              blurRadius: 18,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: ListView.separated(
                          shrinkWrap: true,
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          itemCount: _placeSuggestions.length,
                          separatorBuilder: (_, _) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final place = _placeSuggestions[index];
                            return ListTile(
                              leading: const Icon(
                                Icons.place_outlined,
                                color: _kPurple,
                              ),
                              title: Text(
                                place.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                place.address,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              onTap: () => _selectPlace(place),
                            );
                          },
                        ),
                      ),
                    if (_placeError != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _placeError!,
                        style: const TextStyle(color: Colors.redAccent),
                      ),
                    ],
                    const SizedBox(height: 6),
                    const Text(
                      'Place search powered by Geoapify • © OpenStreetMap contributors',
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                    const SizedBox(height: 20),
                    _SelectTimeCard(
                      hour: _hour,
                      minute: _minute,
                      isAm: _isAm,
                      onHourTap: _cycleHour,
                      onMinuteTap: _cycleMinute,
                      onAmSelected: () => setState(() => _isAm = true),
                      onPmSelected: () => setState(() => _isAm = false),
                    ),
                    const SizedBox(height: 28),
                    if (_submitError != null) ...[
                      Text(
                        _submitError!,
                        style: const TextStyle(
                          color: Colors.redAccent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    _RequestMeetupButton(
                      onPressed: _isSubmitting ? null : _submitMeetup,
                      isLoading: _isSubmitting,
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
}

class _TopBar extends StatelessWidget {
  final String currentUserAvatarUrl;
  final VoidCallback? onBack;

  const _TopBar({required this.currentUserAvatarUrl, this.onBack});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Material(
          color: Colors.white,
          shape: const CircleBorder(),
          elevation: 2,
          shadowColor: _kPurpleDark.withValues(alpha: 0.15),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onBack ?? () => Navigator.pop(context),
            child: const Padding(
              padding: EdgeInsets.all(12),
              child: Icon(Icons.arrow_back, color: _kHeading, size: 20),
            ),
          ),
        ),
        _Avatar(imageUrl: currentUserAvatarUrl, radius: 28),
      ],
    );
  }
}

class _Avatar extends StatelessWidget {
  final String imageUrl;
  final double radius;

  const _Avatar({required this.imageUrl, required this.radius});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      child: CircleAvatar(
        radius: radius,
        backgroundColor: _kLavender,
        backgroundImage: imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
        child: imageUrl.isEmpty
            ? Icon(Icons.person, color: _kPurple, size: radius)
            : null,
      ),
    );
  }
}

class _FieldPill extends StatelessWidget {
  final IconData icon;
  final String hint;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final Widget? trailing;

  const _FieldPill({
    required this.icon,
    required this.hint,
    required this.controller,
    this.keyboardType,
    this.validator,
    this.onChanged,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _kPurpleDark.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: _kLavender,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: _kPurple, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextFormField(
              controller: controller,
              keyboardType: keyboardType,
              validator: validator,
              onChanged: onChanged,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: _kHeading,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                isDense: true,
                hintText: hint,
                hintStyle: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: _kHeading.withValues(alpha: 0.35),
                ),
                errorStyle: const TextStyle(
                  fontSize: 10.5,
                  color: Color(0xFFE0736A),
                ),
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

class _NumberDropdownPill extends StatelessWidget {
  const _NumberDropdownPill({
    required this.icon,
    required this.label,
    required this.value,
    required this.values,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final int value;
  final List<int> values;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _kPurpleDark.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: _kLavender,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: _kPurple, size: 18),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButtonFormField<int>(
              key: ValueKey('$label-$value'),
              initialValue: value,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: label,
                border: InputBorder.none,
                isDense: true,
              ),
              items: values
                  .map(
                    (number) =>
                        DropdownMenuItem(value: number, child: Text('$number')),
                  )
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectTimeCard extends StatelessWidget {
  final int hour;
  final int minute;
  final bool isAm;
  final VoidCallback onHourTap;
  final VoidCallback onMinuteTap;
  final VoidCallback onAmSelected;
  final VoidCallback onPmSelected;

  const _SelectTimeCard({
    required this.hour,
    required this.minute,
    required this.isAm,
    required this.onHourTap,
    required this.onMinuteTap,
    required this.onAmSelected,
    required this.onPmSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
      decoration: BoxDecoration(
        color: _kLavenderCard,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.access_time_filled,
                  color: _kPurple,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Select time',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: _kHeading,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _TimeBox(
                value: hour.toString().padLeft(2, '0'),
                highlighted: true,
                onTap: onHourTap,
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  ':',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: _kHeading,
                  ),
                ),
              ),
              _TimeBox(
                value: minute.toString().padLeft(2, '0'),
                highlighted: false,
                onTap: onMinuteTap,
              ),
              const SizedBox(width: 14),
              _AmPmToggle(
                isAm: isAm,
                onAmSelected: onAmSelected,
                onPmSelected: onPmSelected,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: const [
              SizedBox(
                width: 72,
                child: Text(
                  'Hour',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: _kHeading),
                ),
              ),
              SizedBox(width: 24),
              SizedBox(
                width: 72,
                child: Text(
                  'Minute',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: _kHeading),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _TimeBox extends StatelessWidget {
  final String value;
  final bool highlighted;
  final VoidCallback onTap;

  const _TimeBox({
    required this.value,
    required this.highlighted,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 72,
        height: 72,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: highlighted ? Colors.white : _kMinuteBg,
          borderRadius: BorderRadius.circular(18),
          border: highlighted ? Border.all(color: _kPurple, width: 2) : null,
        ),
        child: Text(
          value,
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w800,
            color: highlighted ? _kPurple : _kHeading,
          ),
        ),
      ),
    );
  }
}

class _AmPmToggle extends StatelessWidget {
  final bool isAm;
  final VoidCallback onAmSelected;
  final VoidCallback onPmSelected;

  const _AmPmToggle({
    required this.isAm,
    required this.onAmSelected,
    required this.onPmSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 72,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: onAmSelected,
              child: Container(
                width: double.infinity,
                color: isAm ? _kPurple : Colors.white,
                alignment: Alignment.center,
                child: Text(
                  'AM',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: isAm ? Colors.white : _kHeading,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: onPmSelected,
              child: Container(
                width: double.infinity,
                color: !isAm ? _kPurple : Colors.white,
                alignment: Alignment.center,
                child: Text(
                  'PM',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: !isAm ? Colors.white : _kHeading,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RequestMeetupButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isLoading;

  const _RequestMeetupButton({
    required this.onPressed,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        onPressed: onPressed,
        style:
            ElevatedButton.styleFrom(
              backgroundColor: _kPurple,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ).copyWith(
              backgroundColor: WidgetStateProperty.all(Colors.transparent),
              shadowColor: WidgetStateProperty.all(Colors.transparent),
            ),
        child: Ink(
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [_kPurple, _kPurpleDark]),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Container(
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.people_alt_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 12),
                if (isLoading)
                  const SizedBox.square(
                    dimension: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                else
                  const Text(
                    'Request Meetup',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
